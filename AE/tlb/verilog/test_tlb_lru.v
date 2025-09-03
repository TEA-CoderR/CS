// test_tlb_lru.v
// LRU替换策略模块单元测试

//`timescale 1ns/1ps
`include "tlb_params.vh"

module test_tlb_lru;

// Inputs
reg [LRU_BITS-1:0] lru_count [0:NUM_WAYS-1];
// reg [NUM_WAYS-1:0][LRU_BITS-1:0] lru_count;

// Outputs
wire [1:0] replace_way;
wire [LRU_BITS-1:0] max_lru_value;

// Test variables
integer test_passed;
integer test_failed;
integer i;

// DUT instantiation
tlb_lru dut (
    .lru_count(lru_count),
    .replace_way(replace_way),
    .max_lru_value(max_lru_value)
);

// Test task
task test_lru(
    input [LRU_BITS-1:0] cnt0,
    input [LRU_BITS-1:0] cnt1,
    input [LRU_BITS-1:0] cnt2,
    input [LRU_BITS-1:0] cnt3,
    input [1:0] exp_way,
    input [LRU_BITS-1:0] exp_max,
    input [127:0] test_name
);
begin
    lru_count[0] = cnt0;
    lru_count[1] = cnt1;
    lru_count[2] = cnt2;
    lru_count[3] = cnt3;
    
    #1; // Wait for combinational logic
    
    if (replace_way !== exp_way) begin
        $display("ERROR [%s]: Replace way mismatch. Expected=%d, Got=%d", 
                 test_name, exp_way, replace_way);
        $display("       LRU counts: [%d, %d, %d, %d]", cnt0, cnt1, cnt2, cnt3);
        test_failed = test_failed + 1;
    end else if (max_lru_value !== exp_max) begin
        $display("ERROR [%s]: Max LRU mismatch. Expected=%d, Got=%d", 
                 test_name, exp_max, max_lru_value);
        $display("       LRU counts: [%d, %d, %d, %d]", cnt0, cnt1, cnt2, cnt3);
        test_failed = test_failed + 1;
    end else begin
        $display("PASS [%s]: way=%d, max=%d", test_name, replace_way, max_lru_value);
        test_passed = test_passed + 1;
    end
end
endtask

// Main test
initial begin
    // Initialize
    test_passed = 0;
    test_failed = 0;
    
    $display("========================================");
    $display("TLB LRU Unit Test Starting");
    $display("========================================");
    
    // Test 1: All zeros - should select way 0
    $display("\nTest 1: All zeros");
    test_lru(4'd0, 4'd0, 4'd0, 4'd0, 2'd0, 4'd0, "All zeros");
    
    // Test 2: Way 0 has minimum
    $display("\nTest 2: Way 0 minimum");
    test_lru(4'd1, 4'd5, 4'd3, 4'd7, 2'd0, 4'd7, "Way 0 minimum");
    
    // Test 3: Way 1 has minimum
    $display("\nTest 3: Way 1 minimum");
    test_lru(4'd8, 4'd2, 4'd6, 4'd4, 2'd1, 4'd8, "Way 1 minimum");
    
    // Test 4: Way 2 has minimum
    $display("\nTest 4: Way 2 minimum");
    test_lru(4'd15, 4'd10, 4'd3, 4'd12, 2'd2, 4'd15, "Way 2 minimum");
    
    // Test 5: Way 3 has minimum
    $display("\nTest 5: Way 3 minimum");
    test_lru(4'd9, 4'd11, 4'd13, 4'd7, 2'd3, 4'd13, "Way 3 minimum");
    
    // Test 6: Multiple ways with same minimum (should select lowest index)
    $display("\nTest 6: Multiple minimums");
    test_lru(4'd5, 4'd5, 4'd8, 4'd10, 2'd0, 4'd10, "Multiple mins - way 0");
    test_lru(4'd8, 4'd5, 4'd5, 4'd10, 2'd1, 4'd10, "Multiple mins - way 1");
    
    // Test 7: Maximum value test (all 15)
    $display("\nTest 7: Maximum values");
    test_lru(4'd15, 4'd15, 4'd15, 4'd15, 2'd0, 4'd15, "All maximum");
    
    // Test 8: Sequential values
    $display("\nTest 8: Sequential values");
    test_lru(4'd0, 4'd1, 4'd2, 4'd3, 2'd0, 4'd3, "Sequential 0-3");
    test_lru(4'd3, 4'd2, 4'd1, 4'd0, 2'd3, 4'd3, "Sequential 3-0");
    
    // Test 9: Edge cases
    $display("\nTest 9: Edge cases");
    test_lru(4'd15, 4'd0, 4'd15, 4'd0, 2'd1, 4'd15, "Alternating max/min");
    test_lru(4'd0, 4'd15, 4'd0, 4'd15, 2'd0, 4'd15, "Alternating min/max");
    
    // Test 10: Random patterns
    $display("\nTest 10: Random patterns");
    test_lru(4'd6, 4'd2, 4'd14, 4'd9, 2'd1, 4'd14, "Random pattern 1");
    test_lru(4'd11, 4'd3, 4'd8, 4'd5, 2'd1, 4'd11, "Random pattern 2");
    test_lru(4'd4, 4'd12, 4'd7, 4'd1, 2'd3, 4'd12, "Random pattern 3");
    
    // Final report
    #10;
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
    #1000;
    $display("ERROR: Test timeout!");
    $finish;
end

endmodule