// test_tlb_storage.v
// TLB存储模块单元测试

//`timescale 1ns/1ps
`include "tlb_params.vh"

module test_tlb_storage;

// Clock and reset
reg clk;
reg rst;

// Read interface
reg [SET_INDEX_BITS-1:0] rd_set_index;
wire                 rd_valid     [0:NUM_WAYS-1];
wire [19:0]          rd_vpn       [0:NUM_WAYS-1];
wire [19:0]          rd_ppn       [0:NUM_WAYS-1];
wire [1:0]           rd_perms     [0:NUM_WAYS-1];
wire [LRU_BITS-1:0]  rd_lru_count [0:NUM_WAYS-1];
// wire [NUM_WAYS-1:0]                 rd_valid;
// wire [NUM_WAYS-1:0][19:0]           rd_vpn;
// wire [NUM_WAYS-1:0][19:0]           rd_ppn;
// wire [NUM_WAYS-1:0][1:0]            rd_perms;
// wire [NUM_WAYS-1:0][LRU_BITS-1:0]   rd_lru_count;

// Write interface
reg wr_en;
reg [SET_INDEX_BITS-1:0] wr_set_index;
reg [1:0] wr_way;
reg wr_valid;
reg [19:0] wr_vpn;
reg [19:0] wr_ppn;
reg [1:0] wr_perms;
reg [LRU_BITS-1:0] wr_lru_count;

// LRU update interface
reg lru_update_en;
reg [SET_INDEX_BITS-1:0] lru_set_index;
reg [1:0] lru_way;
reg [LRU_BITS-1:0] lru_value;

// Test variables
integer test_passed;
integer test_failed;
integer i;

// DUT instantiation
tlb_storage dut (
    .clk(clk),
    .rst(rst),
    .rd_set_index(rd_set_index),
    .rd_valid(rd_valid),
    .rd_vpn(rd_vpn),
    .rd_ppn(rd_ppn),
    .rd_perms(rd_perms),
    .rd_lru_count(rd_lru_count),
    .wr_en(wr_en),
    .wr_set_index(wr_set_index),
    .wr_way(wr_way),
    .wr_valid(wr_valid),
    .wr_vpn(wr_vpn),
    .wr_ppn(wr_ppn),
    .wr_perms(wr_perms),
    .wr_lru_count(wr_lru_count),
    .lru_update_en(lru_update_en),
    .lru_set_index(lru_set_index),
    .lru_way(lru_way),
    .lru_value(lru_value)
);

// Clock generation
always #5 clk = ~clk;

// Test tasks
task reset_dut;
begin
    rst = 1'b1;
    wr_en = 1'b0;
    lru_update_en = 1'b0;
    @(posedge clk);
    @(posedge clk);
    rst = 1'b0;
    @(posedge clk);
end
endtask

task write_entry(
    input [SET_INDEX_BITS-1:0] set,
    input [1:0] way,
    input [19:0] vpn,
    input [19:0] ppn,
    input [1:0] perms
);
begin
    @(posedge clk);
    wr_en = 1'b1;
    wr_set_index = set;
    wr_way = way;
    wr_valid = 1'b1;
    wr_vpn = vpn;
    wr_ppn = ppn;
    wr_perms = perms;
    wr_lru_count = 4'd0;
    @(posedge clk);
    wr_en = 1'b0;
end
endtask

task read_and_verify(
    input [SET_INDEX_BITS-1:0] set,
    input [1:0] way,
    input [19:0] exp_vpn,
    input [19:0] exp_ppn,
    input [1:0] exp_perms,
    input exp_valid
);
begin
    rd_set_index = set;
    #1; // Wait for combinational logic
    
    if (rd_valid[way] !== exp_valid) begin
        $display("ERROR: Valid mismatch at set=%d, way=%d. Expected=%b, Got=%b", 
                 set, way, exp_valid, rd_valid[way]);
        test_failed = test_failed + 1;
    end else if (exp_valid) begin
        if (rd_vpn[way] !== exp_vpn) begin
            $display("ERROR: VPN mismatch at set=%d, way=%d. Expected=%h, Got=%h", 
                     set, way, exp_vpn, rd_vpn[way]);
            test_failed = test_failed + 1;
        end else if (rd_ppn[way] !== exp_ppn) begin
            $display("ERROR: PPN mismatch at set=%d, way=%d. Expected=%h, Got=%h", 
                     set, way, exp_ppn, rd_ppn[way]);
            test_failed = test_failed + 1;
        end else if (rd_perms[way] !== exp_perms) begin
            $display("ERROR: Perms mismatch at set=%d, way=%d. Expected=%b, Got=%b", 
                     set, way, exp_perms, rd_perms[way]);
            test_failed = test_failed + 1;
        end else begin
            test_passed = test_passed + 1;
        end
    end else begin
        test_passed = test_passed + 1;
    end
end
endtask

task update_lru(
    input [SET_INDEX_BITS-1:0] set,
    input [1:0] way,
    input [LRU_BITS-1:0] value
);
begin
    @(posedge clk);
    lru_update_en = 1'b1;
    lru_set_index = set;
    lru_way = way;
    lru_value = value;
    @(posedge clk);
    lru_update_en = 1'b0;
end
endtask

// Main test
initial begin
    // Initialize
    clk = 1'b0;
    test_passed = 0;
    test_failed = 0;
    
    $display("========================================");
    $display("TLB Storage Unit Test Starting");
    $display("========================================");
    
    // Test 1: Reset functionality
    $display("\nTest 1: Reset functionality");
    reset_dut();
    
    // Verify all entries are invalid after reset
    for (i = 0; i < NUM_SETS; i = i + 1) begin
        read_and_verify(i[SET_INDEX_BITS-1:0], 2'd0, 20'd0, 20'd0, 2'b00, 1'b0);
    end
    $display("Test 1 completed");
    
    // Test 2: Write and read single entry
    $display("\nTest 2: Write and read single entry");
    write_entry(4'd5, 2'd2, 20'hABCDE, 20'h12345, 2'b11);
    read_and_verify(4'd5, 2'd2, 20'hABCDE, 20'h12345, 2'b11, 1'b1);
    $display("Test 2 completed");
    
    // Test 3: Write multiple entries in same set
    $display("\nTest 3: Write multiple entries in same set");
    write_entry(4'd3, 2'd0, 20'h11111, 20'h22222, 2'b01);
    write_entry(4'd3, 2'd1, 20'h33333, 20'h44444, 2'b10);
    write_entry(4'd3, 2'd2, 20'h55555, 20'h66666, 2'b11);
    write_entry(4'd3, 2'd3, 20'h77777, 20'h88888, 2'b00);
    
    read_and_verify(4'd3, 2'd0, 20'h11111, 20'h22222, 2'b01, 1'b1);
    read_and_verify(4'd3, 2'd1, 20'h33333, 20'h44444, 2'b10, 1'b1);
    read_and_verify(4'd3, 2'd2, 20'h55555, 20'h66666, 2'b11, 1'b1);
    read_and_verify(4'd3, 2'd3, 20'h77777, 20'h88888, 2'b00, 1'b1);
    $display("Test 3 completed");
    
    // Test 4: Overwrite existing entry
    $display("\nTest 4: Overwrite existing entry");
    write_entry(4'd3, 2'd1, 20'hAAAAA, 20'hBBBBB, 2'b11);
    read_and_verify(4'd3, 2'd1, 20'hAAAAA, 20'hBBBBB, 2'b11, 1'b1);
    $display("Test 4 completed");
    
    // Test 5: LRU update
    $display("\nTest 5: LRU update");
    write_entry(4'd7, 2'd0, 20'h99999, 20'hEEEEE, 2'b11);
    update_lru(4'd7, 2'd0, 4'd15);
    rd_set_index = 4'd7;
    #1;
    if (rd_lru_count[0] !== 4'd15) begin
        $display("ERROR: LRU count mismatch. Expected=%d, Got=%d", 15, rd_lru_count[0]);
        test_failed = test_failed + 1;
    end else begin
        $display("LRU update successful");
        test_passed = test_passed + 1;
    end
    $display("Test 5 completed");
    
    // Test 6: Write to all sets
    $display("\nTest 6: Write to all sets");
    for (i = 0; i < NUM_SETS; i = i + 1) begin
        write_entry(i[SET_INDEX_BITS-1:0], 2'd0, 20'h10000 + i, 20'h20000 + i, 2'b11);
    end
    
    for (i = 0; i < NUM_SETS; i = i + 1) begin
        read_and_verify(i[SET_INDEX_BITS-1:0], 2'd0, 20'h10000 + i, 20'h20000 + i, 2'b11, 1'b1);
    end
    $display("Test 6 completed");
    
    // Test 7: Concurrent write and LRU update (should prioritize write)
    $display("\nTest 7: Concurrent write and LRU update");
    @(posedge clk);
    wr_en = 1'b1;
    wr_set_index = 4'd8;
    wr_way = 2'd1;
    wr_valid = 1'b1;
    wr_vpn = 20'hCCCCC;
    wr_ppn = 20'hDDDDD;
    wr_perms = 2'b10;
    wr_lru_count = 4'd5;
    
    lru_update_en = 1'b1;
    lru_set_index = 4'd8;
    lru_way = 2'd1;
    lru_value = 4'd10;
    
    @(posedge clk);
    wr_en = 1'b0;
    lru_update_en = 1'b0;
    
    rd_set_index = 4'd8;
    #1;
    if (rd_lru_count[1] == 4'd5) begin
        $display("Write priority verified: LRU=%d (expected 5)", rd_lru_count[1]);
        test_passed = test_passed + 1;
    end else begin
        $display("ERROR: Write priority failed");
        test_failed = test_failed + 1;
    end
    $display("Test 7 completed");
    
    // Final report
    #100;
    $display("\n========================================");
    $display("Test Summary:");
    $display("Passed: %d", test_passed);
    $display("Failed: %d", test_failed);
    if (test_failed == 0) begin
        $display("ALL TESTS PASSED!");
    end else begin
        $display("SOME TESTS FAILED!");
    end
    $display("========================================");
    
    $finish;
end

// Timeout
initial begin
    #10000;
    $display("ERROR: Test timeout!");
    $finish;
end

endmodule