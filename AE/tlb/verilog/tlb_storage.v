// tlb_storage.v

`include "tlb_params.vh"

module tlb_storage (
    input clk,
    input rst,
    
    // Read interface
    input [SET_INDEX_BITS-1:0] rd_set_index,
    output reg                 rd_valid     [0:NUM_WAYS-1],
    output reg [19:0]          rd_vpn       [0:NUM_WAYS-1],
    output reg [19:0]          rd_ppn       [0:NUM_WAYS-1],
    output reg [1:0]           rd_perms     [0:NUM_WAYS-1],
    output reg [LRU_BITS-1:0]  rd_lru_count [0:NUM_WAYS-1],
    // input  [SET_INDEX_BITS-1:0]               rd_set_index,
    // output reg [NUM_WAYS-1:0]                 rd_valid,
    // output reg [NUM_WAYS-1:0][19:0]           rd_vpn,
    // output reg [NUM_WAYS-1:0][19:0]           rd_ppn,
    // output reg [NUM_WAYS-1:0][1:0]            rd_perms,
    // output reg [NUM_WAYS-1:0][LRU_BITS-1:0]   rd_lru_count,
    
    // Write interface
    input wr_en,
    input [SET_INDEX_BITS-1:0] wr_set_index,
    input [1:0] wr_way,
    input wr_valid,
    input [19:0] wr_vpn,
    input [19:0] wr_ppn,
    input [1:0] wr_perms,
    input [LRU_BITS-1:0] wr_lru_count,
    
    // LRU update interface
    input lru_update_en,
    input [SET_INDEX_BITS-1:0] lru_set_index,
    input [1:0] lru_way,
    input [LRU_BITS-1:0] lru_value
);

// TLB storage structure (2D arrays)
reg                 tlb_valid     [0:NUM_SETS-1][0:NUM_WAYS-1];
reg [19:0]          tlb_vpn       [0:NUM_SETS-1][0:NUM_WAYS-1];
reg [19:0]          tlb_ppn       [0:NUM_SETS-1][0:NUM_WAYS-1];
reg [1:0]           tlb_perms     [0:NUM_SETS-1][0:NUM_WAYS-1];
reg [LRU_BITS-1:0]  tlb_lru_count [0:NUM_SETS-1][0:NUM_WAYS-1];

// reg [NUM_WAYS-1:0]                tlb_valid     [0:NUM_SETS-1];
// reg [NUM_WAYS-1:0][19:0]          tlb_vpn       [0:NUM_SETS-1];
// reg [NUM_WAYS-1:0][19:0]          tlb_ppn       [0:NUM_SETS-1];
// reg [NUM_WAYS-1:0][1:0]           tlb_perms     [0:NUM_SETS-1];
// reg [NUM_WAYS-1:0][LRU_BITS-1:0]  tlb_lru_count [0:NUM_SETS-1];

// Initialize TLB entries
initial begin
    integer s, w;
    for (s = 0; s < NUM_SETS; s = s + 1) begin
        for (w = 0; w < NUM_WAYS; w = w + 1) begin
            tlb_valid[s][w]      = 1'b0;
            tlb_vpn[s][w]        = 20'd0;
            tlb_ppn[s][w]        = 20'd0;
            tlb_perms[s][w]      = 2'b00;
            tlb_lru_count[s][w]  = {LRU_BITS{1'b0}};
        end
    end
end

// Read logic
integer r;
always @(*) begin
    for (r = 0; r < NUM_WAYS; r = r + 1) begin
        rd_valid[r]     = tlb_valid[rd_set_index][r];
        rd_vpn[r]       = tlb_vpn[rd_set_index][r];
        rd_ppn[r]       = tlb_ppn[rd_set_index][r];
        rd_perms[r]     = tlb_perms[rd_set_index][r];
        rd_lru_count[r] = tlb_lru_count[rd_set_index][r];
    end
end

// Write and LRU update logic
always @(posedge clk) begin
    if (rst) begin
        integer s, w;
        for (s = 0; s < NUM_SETS; s = s + 1) begin
            for (w = 0; w < NUM_WAYS; w = w + 1) begin
                tlb_valid[s][w]      <= 1'b0;
                tlb_vpn[s][w]        <= 20'd0;
                tlb_ppn[s][w]        <= 20'd0;
                tlb_perms[s][w]      <= 2'b00;
                tlb_lru_count[s][w]  <= {LRU_BITS{1'b0}};
            end
        end
    end else begin
        // Write operation
        if (wr_en) begin
            tlb_valid[wr_set_index][wr_way]     <= wr_valid;
            tlb_vpn[wr_set_index][wr_way]       <= wr_vpn;
            tlb_ppn[wr_set_index][wr_way]       <= wr_ppn;
            tlb_perms[wr_set_index][wr_way]     <= wr_perms;
            tlb_lru_count[wr_set_index][wr_way] <= wr_lru_count;
        end
        
        // LRU update (for hit case)
        if (lru_update_en/* && !wr_en*/) begin
            tlb_lru_count[lru_set_index][lru_way] <= lru_value;
        end
    end
end

endmodule