module tlb (
    input clk,
    input rst,

    // Processor Interface
    /*---------------------Accept request-----------------------------*/
    input req_valid_i,              // Request valid
    output reg req_ready_o,         // Request ready
    input [31:0] vaddr_i,           // Virtual address input
    input access_type_i,            // Access_type: 0 -> read, 1 -> write
    /*----------------------Send response-----------------------------*/
    output reg resp_valid_o,        // Response valid
    input resp_ready_i,             // Response ready
    output reg [31:0] paddr_o,      // Physical address output
    output reg hit_o,               // TLB hit
    output reg fault_o,             // Access fault

    // PTW Interface
    /*----------------------Send request------------------------------*/
    output reg ptw_req_valid_o,     // PTW request valid
    input ptw_req_ready_i,          // PTW request ready
    output reg [31:0] ptw_vaddr_o,  // PTW virtual address
    /*---------------------Accept response----------------------------*/
    input ptw_resp_valid_i,         // PTW response valid
    output reg ptw_resp_ready_o,    // PTW response ready
    input [31:0] ptw_pte_i          // Page table entry
);

// TLB parameters
parameter NUM_ENTRIES     = 64;    // Total number of entries
parameter NUM_WAYS        = 4;     // Number of ways (set-associative)
parameter NUM_SETS        = 16;    // Number of sets (64/4 = 16)
parameter LRU_BITS        = 4;     // LRU counter bit width
parameter SET_INDEX_BITS  = 4;     // Set index bit width (log2(16) = 4)

// ===================================================================
// Pure Verilog storage (per-way arrays, 1-D memories indexed by set)
// ===================================================================
reg               tlb_valid0 [0:NUM_SETS-1];
reg [19:0]        tlb_vpn0   [0:NUM_SETS-1];
reg [19:0]        tlb_ppn0   [0:NUM_SETS-1];
reg [1:0]         tlb_perm0  [0:NUM_SETS-1];
reg [LRU_BITS-1:0]tlb_lru0   [0:NUM_SETS-1];

reg               tlb_valid1 [0:NUM_SETS-1];
reg [19:0]        tlb_vpn1   [0:NUM_SETS-1];
reg [19:0]        tlb_ppn1   [0:NUM_SETS-1];
reg [1:0]         tlb_perm1  [0:NUM_SETS-1];
reg [LRU_BITS-1:0]tlb_lru1   [0:NUM_SETS-1];

reg               tlb_valid2 [0:NUM_SETS-1];
reg [19:0]        tlb_vpn2   [0:NUM_SETS-1];
reg [19:0]        tlb_ppn2   [0:NUM_SETS-1];
reg [1:0]         tlb_perm2  [0:NUM_SETS-1];
reg [LRU_BITS-1:0]tlb_lru2   [0:NUM_SETS-1];

reg               tlb_valid3 [0:NUM_SETS-1];
reg [19:0]        tlb_vpn3   [0:NUM_SETS-1];
reg [19:0]        tlb_ppn3   [0:NUM_SETS-1];
reg [1:0]         tlb_perm3  [0:NUM_SETS-1];
reg [LRU_BITS-1:0]tlb_lru3   [0:NUM_SETS-1];

// ===================================================================
// State definitions (pure Verilog)
// ===================================================================
localparam [2:0]
    ACCEPT_REQ  = 3'd0,
    LOOKUP      = 3'd1,
    PTW_REQ     = 3'd2,
    PTW_PENDING = 3'd3,
    UPDATE      = 3'd4,
    RESPOND     = 3'd5;

// Internal registers
reg [2:0]  state, next_state;
reg [31:0] vaddr_reg;
reg        access_type_reg;
reg [31:0] pte_reg;             // Store PTE from PTW

// Lookup logic signals
wire [19:0] vpn;                        // Virtual page number
wire [SET_INDEX_BITS-1:0] set_index;    // Set index
wire [11:0] page_offset;                // Page offset

// Intra-set match signals
wire [NUM_WAYS-1:0] match;
wire hit;
wire [1:0] hit_way;
wire [19:0] hit_ppn;
wire [1:0] hit_perms;
wire perm_fault;

// ===================================================================
// Add initialization for tlb entries
// ===================================================================
integer s_init;
initial begin
    integer w;
    // Reset all ways for all sets
    for (s_init = 0; s_init < NUM_SETS; s_init = s_init + 1) begin
        // way 0
        tlb_valid0[s_init] = 1'b0;
        tlb_vpn0[s_init]   = 20'd0;
        tlb_ppn0[s_init]   = 20'd0;
        tlb_perm0[s_init]  = 2'd0;
        tlb_lru0[s_init]   = {LRU_BITS{1'b0}};
        // way 1
        tlb_valid1[s_init] = 1'b0;
        tlb_vpn1[s_init]   = 20'd0;
        tlb_ppn1[s_init]   = 20'd0;
        tlb_perm1[s_init]  = 2'd0;
        tlb_lru1[s_init]   = {LRU_BITS{1'b0}};
        // way 2
        tlb_valid2[s_init] = 1'b0;
        tlb_vpn2[s_init]   = 20'd0;
        tlb_ppn2[s_init]   = 20'd0;
        tlb_perm2[s_init]  = 2'd0;
        tlb_lru2[s_init]   = {LRU_BITS{1'b0}};
        // way 3
        tlb_valid3[s_init] = 1'b0;
        tlb_vpn3[s_init]   = 20'd0;
        tlb_ppn3[s_init]   = 20'd0;
        tlb_perm3[s_init]  = 2'd0;
        tlb_lru3[s_init]   = {LRU_BITS{1'b0}};
    end
end

// ===================================================================
// TLB Lookup Logic (Combinational Logic)
// ===================================================================

// Vpn extraction
assign vpn = vaddr_reg[31:12];

// Set index extraction
assign set_index = vaddr_reg[SET_INDEX_BITS-1+12:12];

// Page offset extraction
assign page_offset = vaddr_reg[11:0];

// Generate match signals within the set (展开为 4 路)
assign match[0] = tlb_valid0[set_index] && (tlb_vpn0[set_index] == vpn);
assign match[1] = tlb_valid1[set_index] && (tlb_vpn1[set_index] == vpn);
assign match[2] = tlb_valid2[set_index] && (tlb_vpn2[set_index] == vpn);
assign match[3] = tlb_valid3[set_index] && (tlb_vpn3[set_index] == vpn);

// Hit detection
assign hit = |match;

// Hit way selection
assign hit_way = match[0] ? 2'd0 :
                 match[1] ? 2'd1 :
                 match[2] ? 2'd2 :
                 match[3] ? 2'd3 : 2'd0;

// Hit PPN and permissions
assign hit_ppn = match[0] ? tlb_ppn0[set_index] :
                 match[1] ? tlb_ppn1[set_index] :
                 match[2] ? tlb_ppn2[set_index] :
                 match[3] ? tlb_ppn3[set_index] : 20'd0;

assign hit_perms = match[0] ? tlb_perm0[set_index] :
                   match[1] ? tlb_perm1[set_index] :
                   match[2] ? tlb_perm2[set_index] :
                   match[3] ? tlb_perm3[set_index] : 2'd0;

// Permission check
assign perm_fault =
    // Read requires read permission
    ((access_type_reg == 1'b0) && !hit_perms[0]) ||
    // Write requires write permission
    ((access_type_reg == 1'b1) && !hit_perms[1]);

// ===================================================================
// Main State Machine
// ===================================================================
always @(posedge clk) begin
    integer replace_way;
    integer max_lru_value;
    integer min_lru_value;

    if (rst) begin
        state <= ACCEPT_REQ;
        req_ready_o <= 1'b1;
        resp_valid_o <= 1'b0;
        paddr_o <= 32'd0;
        hit_o <= 1'b0;
        fault_o <= 1'b0;
        ptw_req_valid_o <= 1'b0;
        ptw_vaddr_o <= 32'd0;
        ptw_resp_ready_o <= 1'b0;

        // Reset Internal registers
        vaddr_reg <= 32'd0;
        access_type_reg <= 1'b0;
        pte_reg <= 32'd0;

    end else begin
        state <= next_state;

        case (state)
            ACCEPT_REQ: begin
                if (req_valid_i) begin
                    vaddr_reg <= vaddr_i;
                    access_type_reg <= access_type_i;
                    // Tlb request completed, close request channel
                    req_ready_o <= 1'b0;

                    next_state <= LOOKUP;
                end
            end

            LOOKUP: begin
                if (hit && !perm_fault) begin
                    // TLB hit with correct permissions
                    paddr_o <= {hit_ppn, page_offset};
                    hit_o <= 1'b1;
                    fault_o <= 1'b0;
                    resp_valid_o <= 1'b1;

                    next_state <= RESPOND;

                    // Update LRU counter: increment for hit way
                    case (hit_way)
                        2'd0: tlb_lru0[set_index] <= tlb_lru0[set_index] + 1'b1;
                        2'd1: tlb_lru1[set_index] <= tlb_lru1[set_index] + 1'b1;
                        2'd2: tlb_lru2[set_index] <= tlb_lru2[set_index] + 1'b1;
                        2'd3: tlb_lru3[set_index] <= tlb_lru3[set_index] + 1'b1;
                    endcase
                end
                else if (hit && perm_fault) begin
                    // Permission fault
                    paddr_o <= 32'd0;
                    hit_o <= 1'b1;
                    fault_o <= 1'b1;
                    resp_valid_o <= 1'b1;

                    next_state <= RESPOND;
                end
                else begin
                    // TLB miss, send ptw request
                    ptw_vaddr_o <= vaddr_reg;
                    ptw_req_valid_o <= 1'b1;

                    next_state <= PTW_REQ;
                end
            end

            PTW_REQ: begin
                if (ptw_req_ready_i) begin
                    // Request completed
                    ptw_req_valid_o <= 1'b0;
                    // Ready to receive ptw response in PTW_PENDING state
                    ptw_resp_ready_o <= 1'b1;

                    next_state <= PTW_PENDING;
                end
            end

            PTW_PENDING: begin
                if (ptw_resp_valid_i) begin
                    // Success, store PTE
                    pte_reg <= ptw_pte_i;
                    // Received ptw response, close ptw response channel
                    ptw_resp_ready_o <= 1'b0;

                    next_state <= UPDATE;
                end
            end

            UPDATE: begin
                // Permission check
                // If ptw fault, pte_reg is "32'h00000000", so pte_reg[0] = pte_reg[1] = 0 => fault = 1
                if (((access_type_reg == 1'b0) && !pte_reg[0]) ||
                    ((access_type_reg == 1'b1) && !pte_reg[1])) begin
                    paddr_o <= 32'd0;
                    fault_o <= 1'b1;
                end else begin
                    // Intra-set LRU calculation: find way with min LRU and max LRU
                    // Read current LRU values
                    integer lru0, lru1, lru2, lru3;
                    lru0 = tlb_lru0[set_index];
                    lru1 = tlb_lru1[set_index];
                    lru2 = tlb_lru2[set_index];
                    lru3 = tlb_lru3[set_index];

                    // Defaults
                    replace_way  = 0;
                    min_lru_value = lru0;
                    max_lru_value = lru0;

                    // Compare way1
                    if (lru1 < min_lru_value) begin
                        min_lru_value = lru1;
                        replace_way = 1;
                    end
                    if (lru1 > max_lru_value) begin
                        max_lru_value = lru1;
                    end
                    // Compare way2
                    if (lru2 < min_lru_value) begin
                        min_lru_value = lru2;
                        replace_way = 2;
                    end
                    if (lru2 > max_lru_value) begin
                        max_lru_value = lru2;
                    end
                    // Compare way3
                    if (lru3 < min_lru_value) begin
                        min_lru_value = lru3;
                        replace_way = 3;
                    end
                    if (lru3 > max_lru_value) begin
                        max_lru_value = lru3;
                    end

                    // Update TLB entry (replace way with lowest LRU)
                    case (replace_way[1:0])
                        2'd0: begin
                            tlb_valid0[set_index] <= 1'b1;
                            tlb_vpn0[set_index]   <= vpn;
                            tlb_ppn0[set_index]   <= pte_reg[31:12];
                            tlb_perm0[set_index]  <= pte_reg[1:0];
                            tlb_lru0[set_index]   <= max_lru_value[LRU_BITS-1:0];
                        end
                        2'd1: begin
                            tlb_valid1[set_index] <= 1'b1;
                            tlb_vpn1[set_index]   <= vpn;
                            tlb_ppn1[set_index]   <= pte_reg[31:12];
                            tlb_perm1[set_index]  <= pte_reg[1:0];
                            tlb_lru1[set_index]   <= max_lru_value[LRU_BITS-1:0];
                        end
                        2'd2: begin
                            tlb_valid2[set_index] <= 1'b1;
                            tlb_vpn2[set_index]   <= vpn;
                            tlb_ppn2[set_index]   <= pte_reg[31:12];
                            tlb_perm2[set_index]  <= pte_reg[1:0];
                            tlb_lru2[set_index]   <= max_lru_value[LRU_BITS-1:0];
                        end
                        2'd3: begin
                            tlb_valid3[set_index] <= 1'b1;
                            tlb_vpn3[set_index]   <= vpn;
                            tlb_ppn3[set_index]   <= pte_reg[31:12];
                            tlb_perm3[set_index]  <= pte_reg[1:0];
                            tlb_lru3[set_index]   <= max_lru_value[LRU_BITS-1:0];
                        end
                    endcase

                    // Output physical address
                    paddr_o <= {pte_reg[31:12], page_offset};
                    fault_o <= 1'b0;
                end

                // Indicate it was a TLB miss but handled
                hit_o <= 1'b0;
                resp_valid_o <= 1'b1;

                next_state <= RESPOND;
            end

            RESPOND: begin
                if (resp_ready_i) begin
                    // Response completed
                    resp_valid_o <= 1'b0;
                    // Ready to receive processor request in ACCEPT_REQ state
                    req_ready_o <= 1'b1;

                    next_state <= ACCEPT_REQ;
                end
            end
        endcase
    end
end

endmodule
