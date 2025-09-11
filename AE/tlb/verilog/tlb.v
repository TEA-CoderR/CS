// tlb.v

`include "tlb_params.vh"

module tlb (
    input clk,
    input rst,

    // Processor Interface
    /*---------------------Accept request-----------------------------*/
    input req_valid_i,              // Request valid
    output req_ready_o,             // Request ready
    input [31:0] vaddr_i,           // Virtual address input
    input access_type_i,            // Access_type: 0 -> read, 1 -> write
    /*----------------------Send response-----------------------------*/
    output resp_valid_o,            // Response valid
    input resp_ready_i,             // Response ready
    output reg [31:0] paddr_o,      // Physical address output
    output reg hit_o,               // TLB hit
    output reg fault_o,             // Access fault

    // PTW Interface
    /*----------------------Send request------------------------------*/
    output ptw_req_valid_o,         // PTW request valid
    input ptw_req_ready_i,          // PTW request ready
    output reg [31:0] ptw_vaddr_o,  // PTW virtual address
    /*---------------------Accept response----------------------------*/
    input ptw_resp_valid_i,         // PTW response valid
    output ptw_resp_ready_o,        // PTW response ready
    input [31:0] ptw_pte_i          // Page table entry
);

// Internal registers
reg [31:0] vaddr_reg;
reg access_type_reg;
reg [31:0] pte_reg;

// Control signals
wire [2:0] state, next_state;
wire lookup_en, update_en, lru_update_en;

// Storage interface signals
wire [SET_INDEX_BITS-1:0] set_index;
wire                 rd_valid     [0:NUM_WAYS-1];
wire [19:0]          rd_vpn       [0:NUM_WAYS-1];
wire [19:0]          rd_ppn       [0:NUM_WAYS-1];
wire [1:0]           rd_perms     [0:NUM_WAYS-1];
wire [LRU_BITS-1:0]  rd_lru_count [0:NUM_WAYS-1];

// Lookup signals
wire [19:0] vpn;
wire [11:0] page_offset;
wire hit;
wire [1:0] hit_way;
wire [19:0] hit_ppn;
wire [1:0] hit_perms;
wire perm_fault;

// LRU signals
wire [1:0] replace_way;
wire [LRU_BITS-1:0] max_lru_value;

// Write signals
reg wr_en;
reg [1:0] wr_way;
reg wr_valid;
reg [19:0] wr_vpn;
reg [19:0] wr_ppn;
reg [1:0] wr_perms;
reg [LRU_BITS-1:0] wr_lru_count;

// Instantiate controller
tlb_controller controller (
    .clk(clk),
    .rst(rst),
    .req_valid_i(req_valid_i),
    .resp_ready_i(resp_ready_i),
    .req_ready_o(req_ready_o),
    .resp_valid_o(resp_valid_o),
    .ptw_req_ready_i(ptw_req_ready_i),
    .ptw_resp_valid_i(ptw_resp_valid_i),
    .ptw_req_valid_o(ptw_req_valid_o),
    .ptw_resp_ready_o(ptw_resp_ready_o),
    .hit(hit),
    .perm_fault(perm_fault),
    .lookup_en(lookup_en),
    .update_en(update_en),
    .lru_update_en(lru_update_en),
    .state(state),
    .next_state(next_state)
);

// Instantiate storage
tlb_storage storage (
    .clk(clk),
    .rst(rst),
    .rd_set_index(set_index),
    .rd_valid(rd_valid),
    .rd_vpn(rd_vpn),
    .rd_ppn(rd_ppn),
    .rd_perms(rd_perms),
    .rd_lru_count(rd_lru_count),
    .wr_en(wr_en),
    .wr_set_index(set_index),
    .wr_way(wr_way),
    .wr_valid(wr_valid),
    .wr_vpn(wr_vpn),
    .wr_ppn(wr_ppn),
    .wr_perms(wr_perms),
    .wr_lru_count(wr_lru_count),
    .lru_update_en(state == LOOKUP && hit && !perm_fault),
    .lru_set_index(set_index),
    .lru_way(hit_way),
    .lru_value(rd_lru_count[hit_way] + 1'b1)
);

// Instantiate lookup logic
tlb_lookup lookup (
    .vaddr(vaddr_reg),
    .access_type(access_type_reg),
    .tlb_valid(rd_valid),
    .tlb_vpn(rd_vpn),
    .tlb_ppn(rd_ppn),
    .tlb_perms(rd_perms),
    .vpn(vpn),
    .set_index(set_index),
    .page_offset(page_offset),
    .hit(hit),
    .hit_way(hit_way),
    .hit_ppn(hit_ppn),
    .hit_perms(hit_perms),
    .perm_fault(perm_fault)
);

// Instantiate LRU logic
tlb_lru lru (
    .lru_count(rd_lru_count),
    .replace_way(replace_way),
    .max_lru_value(max_lru_value)
);

// Register updates and output logic
always @(posedge clk) begin
    if (rst) begin
        vaddr_reg       <= 32'd0;
        access_type_reg <= 1'b0;
        pte_reg         <= 32'd0;
        ptw_vaddr_o     <= 32'd0;
        paddr_o         <= 32'd0;
        hit_o           <= 1'b0;
        fault_o         <= 1'b0;
        wr_en           <= 1'b0;
    end else begin
        wr_en <= 1'b0;  // Default
        // $display("----------test_tlb------------%d", state == LOOKUP && hit && !perm_fault); 
        case (state)
            ACCEPT_REQ: begin
                if (req_valid_i && req_ready_o) begin
                    vaddr_reg       <= vaddr_i;
                    access_type_reg <= access_type_i;
                end
            end
            
            LOOKUP: begin
                $display("  vaddr=0x%08h", vaddr_reg);
                if (hit && !perm_fault) begin
                    $display("hit");  
                    paddr_o <= {hit_ppn, page_offset};
                    hit_o   <= 1'b1;
                    fault_o <= 1'b0;
                end else if (hit && perm_fault) begin
                    paddr_o <= 32'd0;
                    hit_o   <= 1'b1;
                    fault_o <= 1'b1;
                end else begin
                    $display("miss");  
                    ptw_vaddr_o <= vaddr_reg;
                end
            end
            
            PTW_PENDING: begin
                if (ptw_resp_valid_i && ptw_resp_ready_o) begin
                    pte_reg <= ptw_pte_i;
                end
            end
            
            UPDATE: begin
                // Permission check
                if ((access_type_reg == 1'b0 && !pte_reg[0]) ||
                    (access_type_reg == 1'b1 && !pte_reg[1])) begin
                    paddr_o <= 32'd0;
                    fault_o <= 1'b1;
                end else begin
                    $display("update");    
                    // Update TLB entry
                    wr_en        <= 1'b1;
                    wr_way       <= replace_way;
                    wr_valid     <= 1'b1;
                    wr_vpn       <= vpn;
                    wr_ppn       <= pte_reg[31:12];
                    wr_perms     <= pte_reg[1:0];
                    wr_lru_count <= max_lru_value == 0 ? 1 : max_lru_value;
                    
                    // Output physical address
                    paddr_o <= {pte_reg[31:12], page_offset};
                    fault_o <= 1'b0;
                end
                hit_o <= 1'b0;
            end
            
            RESPOND: begin
                if (resp_ready_i && resp_valid_o) begin
                    hit_o   <= 1'b0;
                    fault_o <= 1'b0;
                    wr_en   <= 1'b0;
                end
            end
        endcase
    end
end

endmodule