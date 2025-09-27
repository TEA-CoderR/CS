// tlb_lru.v

`include "tlb_params.vh"

module tlb_lru (
    // LRU counters from storage
    input [LRU_BITS-1:0] lru_count [0:NUM_WAYS-1],
    // input [NUM_WAYS-1:0][LRU_BITS-1:0] lru_count,
    
    // Replace way selection
    output reg [1:0] replace_way,
    output reg [LRU_BITS-1:0] max_lru_value
);

// LRU calculation: find way with minimum LRU value
integer i;
reg [LRU_BITS-1:0] min_lru_value;

always @(*) begin
    replace_way    = 2'd0;
    min_lru_value  = lru_count[0];
    max_lru_value  = lru_count[0];
    $display("lru_count[%d]=%d", 0, lru_count[0]);
    for (i = 1; i < NUM_WAYS; i = i + 1) begin
        if (lru_count[i] < min_lru_value) begin
            min_lru_value = lru_count[i];
            replace_way   = i[1:0];
        end
        if (lru_count[i] > max_lru_value) begin
            max_lru_value = lru_count[i];
        end
        $display("lru_count[%d]=%d", i, lru_count[i]);
    end
    $display("replace_way=%d", replace_way);
end

endmodule