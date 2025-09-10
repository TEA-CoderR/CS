// test_memory.v

module test_memory;

// Clock and reset
reg clk;
reg rst;

// Memory Interface
reg mem_req_valid_i;
wire mem_req_ready_o;
reg [31:0] mem_addr_i;

wire mem_resp_valid_o;
reg mem_resp_ready_i;
wire [31:0] mem_data_o;

// Test variables
integer test_passed;
integer test_failed;
reg [31:0] test_addr;
reg [31:0] expected_data;
reg [31:0] received_data;

// DUT instantiation
memory dut (
    .clk(clk),
    .rst(rst),
    .mem_req_valid_i(mem_req_valid_i),
    .mem_req_ready_o(mem_req_ready_o),
    .mem_addr_i(mem_addr_i),
    .mem_resp_valid_o(mem_resp_valid_o),
    .mem_resp_ready_i(mem_resp_ready_i),
    .mem_data_o(mem_data_o)
);

// Clock generation
always #5 clk = ~clk;

// Test tasks
task reset_dut;
begin
    rst = 1'b1;
    mem_req_valid_i = 1'b0;
    mem_resp_ready_i = 1'b0;
    mem_addr_i = 32'h00000000;
    @(posedge clk);
    @(posedge clk);
    rst = 1'b0;
    @(posedge clk);
end
endtask

task memory_read(
    input  [31:0] addr,
    output [31:0] data_result
);
begin
    // 1. Send Request
    mem_req_valid_i = 1'b1;
    mem_addr_i      = addr;

    // 2. Waiting for the memory interface to be ready
    do @(posedge clk); while (mem_req_ready_o !== 1'b1);
    @(posedge clk);
    mem_req_valid_i = 1'b0;
    
    // 3. Awaiting Response
    mem_resp_ready_i = 1'b1;
    do @(posedge clk); while (mem_resp_valid_o !== 1'b1);
    // @(posedge clk);
    data_result      = mem_data_o;
    
    // mem_resp_ready_i = 1'b1;
    // @(posedge clk);
    @(posedge clk);
    mem_resp_ready_i = 1'b0;
    @(posedge clk);
end
endtask

task verify_read(
    input [31:0] addr,
    input [31:0] exp_data,
    input [255:0] test_name
);
begin
    memory_read(addr, received_data);
    if (received_data !== exp_data) begin
        $display("ERROR [%s]: Data mismatch", test_name);
        $display("  Address:  0x%08h", addr);
        $display("  Expected: 0x%08h", exp_data);
        $display("  Got:      0x%08h", received_data);
        test_failed = test_failed + 1;
    end else begin
        $display("PASS [%s]: addr=0x%08h, data=0x%08h", test_name, addr, received_data);
        test_passed = test_passed + 1;
    end
end
endtask

// Main test sequence
integer i;
reg [31:0] test_addresses [0:9];
reg [31:0] expected_values [0:9];
initial begin
    // Initialize
    clk = 1'b0;
    test_passed = 0;
    test_failed = 0;
    
    $display("========================================");
    $display("Memory Unit Test Starting (Fixed Version)");
    $display("========================================");
    
    // Test 1: Reset functionality
    $display("\n=== Test 1: Reset Functionality ===");
    reset_dut();
    if (!mem_req_ready_o) begin
        $display("ERROR: Memory not ready after reset");
        test_failed = test_failed + 1;
    end else begin
        $display("PASS: Memory ready after reset");
        test_passed = test_passed + 1;
    end
    
    // Test 2: Read uninitialized memory (should return 0)
    $display("\n=== Test 2: Read Uninitialized Memory ===");
    verify_read(32'h00000000, 32'h00000000, "Start of memory");
    verify_read(32'h00000004, 32'h00000000, "Word 1");
    verify_read(32'h00000100, 32'h00000000, "Different location");
    
    // Test 3: Read initialized page table entries
    $display("\n=== Test 3: Read Page Table Entries ===");
    
    // Root page table at 0x400 (word index 256)
    verify_read(32'h00000400, 32'h00000801, "Root PT entry 0");
    verify_read(32'h00000404, 32'h12340000, "Root PT entry 1");
    verify_read(32'h00000408, 32'h00000000, "Root PT entry 2 (invalid)");
    
    // Level 2 page table at 0x800 (word index 512)
    verify_read(32'h00000800, 32'h1000000F, "L2 PT entry 0");
    verify_read(32'h00000804, 32'h1100000F, "L2 PT entry 1");
    verify_read(32'h00000808, 32'h12000007, "L2 PT entry 2");
    verify_read(32'h0000080C, 32'h00000000, "L2 PT entry 3 (invalid)");
            
    // Test 4: Out of range access
    $display("\n=== Test 4: Out of Range Access ===");
    verify_read(32'h00001000, 32'h00000000, "Just out of range (word 1024)");
    verify_read(32'h00010000, 32'h00000000, "Far out of range");
    
    // Test 5: Stress test
    $display("\n=== Test 5: Stress Test ===");
    
    test_addresses[0] = 32'h00000000; expected_values[0] = 32'h00000000;
    test_addresses[1] = 32'h00000400; expected_values[1] = 32'h00000801;
    test_addresses[2] = 32'h00000404; expected_values[2] = 32'h12340000;
    test_addresses[3] = 32'h00000408; expected_values[3] = 32'h00000000;
    test_addresses[4] = 32'h00000800; expected_values[4] = 32'h1000000F;
    test_addresses[5] = 32'h00000804; expected_values[5] = 32'h1100000F;
    test_addresses[6] = 32'h00000808; expected_values[6] = 32'h12000007;
    test_addresses[7] = 32'h0000080C; expected_values[7] = 32'h00000000;
    test_addresses[8] = 32'h00000FFC; expected_values[8] = 32'h00000000;
    test_addresses[9] = 32'h00001000; expected_values[9] = 32'h00000000;
    
    for (i = 0; i < 10; i = i + 1) begin
        verify_read(test_addresses[i], expected_values[i], "Stress test");
    end
    
    // Final report
    #100;
    $display("\n========================================");
    $display("Memory Test Summary:");
    $display("  Tests Passed: %d", test_passed);
    $display("  Tests Failed: %d", test_failed);
    
    if (test_failed == 0) begin
        $display("MEMORY:\t\t ALL TESTS PASSED!");
    end else begin
        $display("MEMORY:\t\t SOME TESTS FAILED!");
    end
    $display("========================================");
    
    $finish;
end

// Timeout watchdog
initial begin
    #50000;
    $display("ERROR: Memory test timeout!");
    $finish;
end

// VCD dump for debugging
initial begin
    $dumpfile("test_memory.vcd");
    $dumpvars(0, test_memory);
end

// DEBUG: Memory monitoring for debugging
// always @(posedge clk) begin
//     $display("Time: %0t, State: %s, req_valid=%b, req_ready=%b, resp_valid=%b, resp_ready=%b", 
//              $time,
//              (dut.state == 2'b00) ? "IDLE" :
//              (dut.state == 2'b01) ? "READ_ACCESS" :
//              (dut.state == 2'b10) ? "RESPOND" : "UNKNOWN",
//              mem_req_valid_i, mem_req_ready_o, mem_resp_valid_o, mem_resp_ready_i);
// end

endmodule

