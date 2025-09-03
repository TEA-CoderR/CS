// Optimized TLB (SystemVerilog)
// Features added:
// 1) Strict valid/ready handshake for processor and PTW interfaces
// 2) 2-stage pipeline (stage0: accept & index, stage1: lookup/response)
// 3) 4-way Tree-PLRU replacement (scales for NUM_WAYS=4)
// 4) Separated combinational next_state logic and synchronous registers
// 5) Synchronous reset initialization (no initial blocks)

module tlb_optimized #(
    parameter NUM_ENTRIES    = 64,
    parameter NUM_WAYS       = 4,
    parameter NUM_SETS       = (NUM_ENTRIES/NUM_WAYS),
    parameter LRU_BITS       = 3,            // tree-PLRU bits for 4-way
    parameter SET_INDEX_BITS = $clog2(NUM_SETS)
)(
    input  logic         clk,
    input  logic         rst,

    // Processor Interface
    input  logic         req_valid_i,
    output logic         req_ready_o,
    input  logic [31:0]  vaddr_i,
    input  logic         access_type_i,   // 0 read, 1 write

    output logic         resp_valid_o,
    input  logic         resp_ready_i,
    output logic [31:0]  paddr_o,
    output logic         hit_o,
    output logic         fault_o,

    // PTW Interface
    output logic         ptw_req_valid_o,
    input  logic         ptw_req_ready_i,
    output logic [31:0]  ptw_vaddr_o,

    input  logic         ptw_resp_valid_i,
    output logic         ptw_resp_ready_o,
    input  logic [31:0]  ptw_pte_i
);

// ------------------------------------------------------------------
// Local types and storage
// ------------------------------------------------------------------
localparam VPN_WIDTH = 20;   // bits [31:12]
localparam PPN_WIDTH = 20;   // bits [31:12]
localparam OFF_WIDTH = 12;

// TLB arrays (synchronous reset)
logic                    tlb_valid   [NUM_SETS-1:0][NUM_WAYS-1:0];
logic [VPN_WIDTH-1:0]    tlb_vpn     [NUM_SETS-1:0][NUM_WAYS-1:0];
logic [PPN_WIDTH-1:0]    tlb_ppn     [NUM_SETS-1:0][NUM_WAYS-1:0];
logic [1:0]              tlb_perms   [NUM_SETS-1:0][NUM_WAYS-1:0];
// PLRU tree bits: for 4-way we can use 3 bits per set
logic [LRU_BITS-1:0]     tlb_plru    [NUM_SETS-1:0];

// ------------------------------------------------------------------
// State machine (separated combinational and sequential)
// ------------------------------------------------------------------
typedef enum logic [2:0] { S_IDLE, S_STAGE1, S_PTW_REQ, S_PTW_WAIT, S_UPDATE, S_RESP } state_t;
state_t state, next_state;

// Pipeline registers (stage0 -> stage1)
logic [31:0] vaddr_s0;
logic        access_type_s0;
logic        s0_valid;   // indicates stage0 captured a request

logic [31:0] vaddr_s1;
logic        access_type_s1;
logic        s1_valid;   // valid for stage1

// Lookup signals (combinational for stage1)
logic [VPN_WIDTH-1:0]     vpn_s1;
logic [SET_INDEX_BITS-1:0] set_idx_s1;
logic [OFF_WIDTH-1:0]     offset_s1;
logic [NUM_WAYS-1:0]     match_vec;
logic                    hit_s1;
logic [$clog2(NUM_WAYS)-1:0] hit_way_s1;
logic [PPN_WIDTH-1:0]    hit_ppn_s1;
logic [1:0]              hit_perms_s1;
logic                    perm_fault_s1;

// Registers to hold PTW/PTE
logic [31:0] pte_reg_s;

// Internal handshake latches
logic ptw_req_sent;   // record that we issued a PTW request (keeps valid high until ready)
logic ptw_resp_received;

// ------------------------------------------------------------------
// Functions: 4-way tree PLRU helpers
// For NUM_WAYS != 4, user will need to adapt to another PLRU.
// ------------------------------------------------------------------
function automatic logic [1:0] plru_select_victim(logic [LRU_BITS-1:0] plru);
    // For a 4-way tree: bit0 = top (0->left,1->right)
    // left subtree uses bit1 (0->way0,1->way1), right subtree uses bit2 (0->way2,1->way3)
    logic [1:0] victim;
    if (plru[LRU_BITS-1]) begin // top = 1 -> choose right subtree
        // choose between way2 and way3 using plru[LRU_BITS-2]
        victim = plru[LRU_BITS-2] ? 2'd3 : 2'd2;
    end else begin
        // choose between way0 and way1 using plru[LRU_BITS-3]
        victim = plru[LRU_BITS-3] ? 2'd1 : 2'd0;
    end
    return victim;
endfunction

function automatic logic [LRU_BITS-1:0] plru_update_on_access(logic [LRU_BITS-1:0] plru, logic [$clog2(NUM_WAYS)-1:0] way);
    logic [LRU_BITS-1:0] new_plru;
    // For 4-way mapping:
    // if way==0 -> top=0 (left), left-bit=0 (favor way1 next)
    // if way==1 -> top=0, left-bit=1
    // if way==2 -> top=1, right-bit=0
    // if way==3 -> top=1, right-bit=1
    new_plru = plru;
    case (way)
        2'd0: begin new_plru[LRU_BITS-1] = 1'b0; new_plru[LRU_BITS-3] = 1'b0; end
        2'd1: begin new_plru[LRU_BITS-1] = 1'b0; new_plru[LRU_BITS-3] = 1'b1; end
        2'd2: begin new_plru[LRU_BITS-1] = 1'b1; new_plru[LRU_BITS-2] = 1'b0; end
        2'd3: begin new_plru[LRU_BITS-1] = 1'b1; new_plru[LRU_BITS-2] = 1'b1; end
        default: new_plru = plru;
    endcase
    return new_plru;
endfunction

// ------------------------------------------------------------------
// Combinational lookup for stage1
// ------------------------------------------------------------------
always_comb begin
    // defaults
    match_vec = '0;
    hit_s1 = 1'b0;
    hit_way_s1 = '0;
    hit_ppn_s1 = '0;
    hit_perms_s1 = 2'b00;
    perm_fault_s1 = 1'b0;

    if (s1_valid) begin
        // extract fields
        vpn_s1 = vaddr_s1[31:12];
        set_idx_s1 = vaddr_s1[SET_INDEX_BITS+11:12];
        offset_s1 = vaddr_s1[11:0];

        // build match vector
        for (int w = 0; w < NUM_WAYS; w++) begin
            match_vec[w] = tlb_valid[set_idx_s1][w] && (tlb_vpn[set_idx_s1][w] == vpn_s1);
        end

        if (|match_vec) begin
            hit_s1 = 1'b1;
            // encode hit_way (priority encoder)
            for (int w = 0; w < NUM_WAYS; w++) begin
                if (match_vec[w]) begin
                    hit_way_s1 = w;
                    hit_ppn_s1 = tlb_ppn[set_idx_s1][w];
                    hit_perms_s1 = tlb_perms[set_idx_s1][w];
                    break;
                end
            end
            // permission check: perms[0]=R OK?, perms[1]=W OK?
            perm_fault_s1 = (access_type_s1 == 1'b0 && !hit_perms_s1[0]) ||
                            (access_type_s1 == 1'b1 && !hit_perms_s1[1]);
        end
    end
end

// ------------------------------------------------------------------
// Next state (combinational) and outputs defaulting
// ------------------------------------------------------------------
always_comb begin
    next_state = state;

    // default outputs
    req_ready_o        = 1'b0;
    resp_valid_o       = 1'b0;
    ptw_req_valid_o    = 1'b0;
    ptw_vaddr_o        = '0;
    ptw_resp_ready_o   = 1'b0;
    paddr_o            = 32'd0;
    hit_o              = 1'b0;
    fault_o            = 1'b0;

    // default pipeline handshake
    // req_ready_o asserted when stage0 free (no s0_valid)
    req_ready_o = ~s0_valid;

    case (state)
        S_IDLE: begin
            // accept new request into stage0
            if (s0_valid) begin
                // advance to stage1
                next_state = S_STAGE1;
            end
        end

        S_STAGE1: begin
            // stage1 performing lookup
            if (s1_valid) begin
                if (hit_s1 && !perm_fault_s1) begin
                    // hit and permission OK -> prepare response
                    resp_valid_o = 1'b1;
                    paddr_o = {hit_ppn_s1, offset_s1};
                    hit_o = 1'b1;
                    fault_o = 1'b0;
                    next_state = S_RESP;
                end else if (hit_s1 && perm_fault_s1) begin
                    // hit but permission fault
                    resp_valid_o = 1'b1;
                    paddr_o = 32'd0;
                    hit_o = 1'b1;
                    fault_o = 1'b1;
                    next_state = S_RESP;
                end else if (s1_valid && !hit_s1) begin
                    // miss: issue PTW request and stay until accepted
                    ptw_req_valid_o = 1'b1;
                    ptw_vaddr_o = vaddr_s1;
                    next_state = S_PTW_REQ;
                end
            end
        end

        S_PTW_REQ: begin
            // maintain ptw_req_valid_o until PTW accepts
            ptw_req_valid_o = 1'b1;
            ptw_vaddr_o = vaddr_s1;
            if (ptw_req_ready_i) begin
                // request accepted, now wait for response
                next_state = S_PTW_WAIT;
            end
        end

        S_PTW_WAIT: begin
            // assert ptw_resp_ready until response arrives
            ptw_resp_ready_o = 1'b1;
            if (ptw_resp_valid_i) begin
                next_state = S_UPDATE;
            end
        end

        S_UPDATE: begin
            // Update TLB with received PTE and prepare response
            // We'll compute paddr and fault in sequential block when pte_reg_s updated
            resp_valid_o = 1'b1;
            next_state = S_RESP;
        end

        S_RESP: begin
            // keep resp_valid asserted until processor accepts response
            resp_valid_o = 1'b1;
            // propagate outputs for response (these are set in sequential block as well)
            if (resp_ready_i) begin
                next_state = S_IDLE;
            end
        end

        default: next_state = S_IDLE;
    endcase
end

// ------------------------------------------------------------------
// Sequential logic: state, pipeline registers, TLB array updates
// ------------------------------------------------------------------
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= S_IDLE;

        s0_valid <= 1'b0;
        s1_valid <= 1'b0;
        vaddr_s0 <= 32'd0;
        access_type_s0 <= 1'b0;
        vaddr_s1 <= 32'd0;
        access_type_s1 <= 1'b0;

        ptw_req_sent <= 1'b0;
        ptw_resp_received <= 1'b0;

        pte_reg_s <= 32'd0;
        paddr_o <= 32'd0;
        hit_o <= 1'b0;
        fault_o <= 1'b0;

        // synchronous reset of arrays
        for (int s = 0; s < NUM_SETS; s++) begin
            tlb_plru[s] = '0;
            for (int w = 0; w < NUM_WAYS; w++) begin
                tlb_valid[s][w] = 1'b0;
                tlb_vpn[s][w]   = '0;
                tlb_ppn[s][w]   = '0;
                tlb_perms[s][w] = 2'b00;
            end
        end
    end else begin
        state <= next_state;

        // --------- Stage0 capture (accept) ---------
        if (req_valid_i && req_ready_o) begin
            // capture request into stage0
            s0_valid <= 1'b1;
            vaddr_s0 <= vaddr_i;
            access_type_s0 <= access_type_i;
        end else if (s0_valid && ~s1_valid) begin
            // if stage1 free, advance
            s0_valid <= 1'b0;
        end

        // --------- Stage1 pipeline advance ---------
        if (s0_valid && ~s1_valid) begin
            // advance captured request to stage1
            s1_valid <= 1'b1;
            vaddr_s1 <= vaddr_s0;
            access_type_s1 <= access_type_s0;
            // clear stage0
            s0_valid <= 1'b0;
        end else if (state == S_STAGE1 && next_state == S_PTW_REQ) begin
            // keep s1_valid = 1 while waiting for PTW
            s1_valid <= s1_valid; // no change
        end else if (state == S_RESP && resp_ready_i) begin
            // response accepted -> clear stage1
            s1_valid <= 1'b0;
        end

        // --------- PTW handshake tracking ---------
        // ptw_req_valid_o is driven combinationally; record when we have sent
        if (state == S_PTW_REQ && ptw_req_valid_o) begin
            // if PTW accepted this cycle
            if (ptw_req_ready_i) begin
                ptw_req_sent <= 1'b1;
            end else begin
                ptw_req_sent <= ptw_req_sent; // hold until accepted
            end
        end else if (state == S_IDLE) begin
            ptw_req_sent <= 1'b0;
        end

        // Capture PTW response when valid & ready
        if (state == S_PTW_WAIT && ptw_resp_valid_i && ptw_resp_ready_o) begin
            pte_reg_s <= ptw_pte_i;
            ptw_resp_received <= 1'b1;
        end

        // --------- Update TLB on PTW response ---------
        if (state == S_UPDATE) begin
            // Check for permission fault in PTE
            logic pte_r = pte_reg_s[0];
            logic pte_w = pte_reg_s[1];

            if ((access_type_s1 == 1'b0 && !pte_r) || (access_type_s1 == 1'b1 && !pte_w)) begin
                // permission fault -> respond with fault
                paddr_o <= 32'd0;
                hit_o <= 1'b0;
                fault_o <= 1'b1;
            end else begin
                // choose victim via PLRU
                logic [1:0] victim_way = plru_select_victim(tlb_plru[set_idx_s1]);

                // write new entry
                tlb_valid[set_idx_s1][victim_way] <= 1'b1;
                tlb_vpn[set_idx_s1][victim_way]   <= vaddr_s1[31:12];
                tlb_ppn[set_idx_s1][victim_way]   <= pte_reg_s[31:12];
                tlb_perms[set_idx_s1][victim_way] <= pte_reg_s[1:0];

                // update PLRU to record access (new entry is "accessed")
                tlb_plru[set_idx_s1] <= plru_update_on_access(tlb_plru[set_idx_s1], victim_way);

                // form physical addr
                paddr_o <= {pte_reg_s[31:12], vaddr_s1[11:0]};
                hit_o <= 1'b0;
                fault_o <= 1'b0;
            end
            // clear PTW received flag
            ptw_resp_received <= 1'b0;
        end

        // --------- On a hit in stage1 we must update PLRU and outputs ---------
        if (state == S_STAGE1 && hit_s1 && !perm_fault_s1) begin
            // update PLRU for the hit way
            tlb_plru[set_idx_s1] <= plru_update_on_access(tlb_plru[set_idx_s1], hit_way_s1);

            // prepare outputs (also driven combinationally for response)
            paddr_o <= {hit_ppn_s1, offset_s1};
            hit_o <= 1'b1;
            fault_o <= 1'b0;
        end else if (state == S_STAGE1 && hit_s1 && perm_fault_s1) begin
            paddr_o <= 32'd0;
            hit_o <= 1'b1;
            fault_o <= 1'b1;
        end

    end
end

endmodule
