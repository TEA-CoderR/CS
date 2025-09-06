// // 优化后的memory_read任务 - 正确的握手协议
// task memory_read(
//     input [31:0] addr,
//     output [31:0] data_result
// );
// begin
//     // 步骤1: 等待memory准备接受请求
//     @(posedge clk);
//     while (!mem_req_ready_o) @(posedge clk);
    
//     // 步骤2: 发送请求
//     mem_req_valid_i = 1'b1;
//     mem_addr_i = addr;
//     $display("  [READ] Sending request to addr=0x%08h", addr);
    
//     // 步骤3: 等待请求被接受
//     do @(posedge clk); while (!mem_req_ready_o || !mem_req_valid_i);
    
//     // 步骤4: 清除请求信号
//     mem_req_valid_i = 1'b0;
    
//     // 步骤5: 准备接收响应
//     mem_resp_ready_i = 1'b1;
    
//     // 步骤6: 等待响应
//     while (!mem_resp_valid_o) @(posedge clk);
    
//     // 步骤7: 获取数据
//     data_result = mem_data_o;
//     $display("  [READ] Received data=0x%08h", data_result);
    
//     // 步骤8: 等待一个时钟周期确保握手完成
//     @(posedge clk);
    
//     // 步骤9: 清除响应准备信号
//     mem_resp_ready_i = 1'b0;
//     @(posedge clk);
// end
// endtask

// test_memory.v
// Memory 模块单元测试 - 修复版本，确保所有地址都正确

//`timescale 1ns/1ps

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

// task memory_read(
//     input [31:0] addr,
//     output [31:0] data_result
// );
// begin
//     // Send memory request
//     //@(posedge clk);
//     wait(mem_req_ready_o);
//     mem_req_valid_i = 1'b1;
//     mem_addr_i = addr;
//     @(posedge clk);
//     @(posedge clk);
//     mem_req_valid_i = 1'b0;
    
//     // Wait for response
//     wait(mem_resp_valid_o);
//     data_result = mem_data_o;
//     mem_resp_ready_i = 1'b1;
//     @(posedge clk);
//     @(posedge clk);
//     mem_resp_ready_i = 1'b0;
//     @(posedge clk);
// end
// endtask

task memory_read(
    input  [31:0] addr,
    output [31:0] data_result
);
begin
    // 1. 等待 memory 接口准备好
    while (mem_req_ready_o !== 1'b1) begin
        @(mem_req_ready_o);  // 等待信号变化，再检查条件
    end

    // 2. 发起请求
    mem_req_valid_i = 1'b1;
    mem_addr_i      = addr;
    @(posedge clk);
    @(posedge clk);
    mem_req_valid_i = 1'b0;
    
    // 3. 等待响应
    while (mem_resp_valid_o !== 1'b1) begin
        @(mem_resp_valid_o); // 等待信号变化，再检查条件
    end
    data_result      = mem_data_o;
    mem_resp_ready_i = 1'b1;
    @(posedge clk);
    @(posedge clk);
    mem_resp_ready_i = 1'b0;
    @(posedge clk);
end
endtask


// task memory_read(
//     input [31:0] addr,
//     output [31:0] data_result
// );
// begin
//     @(posedge clk);
//     while (!mem_req_ready_o) @(posedge clk);

//     mem_req_valid_i = 1'b1;
//     mem_addr_i = addr;
//     @(posedge clk);
//     mem_req_valid_i = 1'b0;

//     while (!mem_resp_valid_o) @(posedge clk);
//     data_result = mem_data_o;
//     mem_resp_ready_i = 1'b1;
//     @(posedge clk);
//     mem_resp_ready_i = 1'b0;
// end
// endtask


task verify_result(
    input [31:0] got_data,
    input [31:0] exp_data,
    input [255:0] test_name
);
begin
    if (got_data !== exp_data) begin
        $display("ERROR [%s]: Data mismatch", test_name);
        $display("  Expected: 0x%08h", exp_data);
        $display("  Got:      0x%08h", got_data);
        test_failed = test_failed + 1;
    end else begin
        $display("PASS [%s]: data=0x%08h", test_name, got_data);
        test_passed = test_passed + 1;
    end
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
reg [31:0] rapid_addresses [0:4];
reg [31:0] rapid_expected [0:4];
reg [31:0] test_addresses [0:9];
reg [31:0] expected_values [0:9];
initial begin
    $dumpfile("test_memory.vcd");
    $dumpvars(0, test_memory);
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
    verify_read(32'h00000404, 32'h12340007, "Root PT entry 1");
    verify_read(32'h00000408, 32'h00000000, "Root PT entry 2 (invalid)");
    
    // Level 2 page table at 0x800 (word index 512)
    verify_read(32'h00000800, 32'h1000000F, "L2 PT entry 0");
    verify_read(32'h00000804, 32'h1100000F, "L2 PT entry 1");
    verify_read(32'h00000808, 32'h12000007, "L2 PT entry 2");
    verify_read(32'h0000080C, 32'h00000000, "L2 PT entry 3 (invalid)");
    
    // Test 4: Word alignment verification
    $display("\n=== Test 4: Word Alignment Test ===");
    verify_read(32'h00000400, 32'h00000801, "Word aligned 0x400");
    verify_read(32'h00000404, 32'h12340007, "Word aligned 0x404");
    verify_read(32'h00000408, 32'h00000000, "Word aligned 0x408");
    verify_read(32'h0000040C, 32'h00000000, "Word aligned 0x40C");
    
    // Test 5: Address boundary tests
    $display("\n=== Test 5: Address Boundary Tests ===");
    verify_read(32'h00000000, 32'h00000000, "Start of memory");
    verify_read(32'h00000FFC, 32'h00000000, "End of range (word 1023)");
    
    // Test 6: Out of range access
    $display("\n=== Test 6: Out of Range Access ===");
    verify_read(32'h00001000, 32'h00000000, "Just out of range");
    verify_read(32'h00010000, 32'h00000000, "Far out of range");
    
    // Test 7: Page table structure verification
    $display("\n=== Test 7: Page Table Structure Scan ===");
    $display("Root page table area (0x400-0x410):");
    for (test_addr = 32'h400; test_addr <= 32'h410; test_addr = test_addr + 4) begin
        memory_read(test_addr, received_data);
        $display("  0x%08h -> 0x%08h", test_addr, received_data);
    end
    
    $display("Level 2 page table area (0x800-0x810):");
    for (test_addr = 32'h800; test_addr <= 32'h810; test_addr = test_addr + 4) begin
        memory_read(test_addr, received_data);
        $display("  0x%08h -> 0x%08h", test_addr, received_data);
    end
    
    // Test 8: Back-to-back requests
    $display("\n=== Test 8: Back-to-Back Requests ===");
    verify_read(32'h00000400, 32'h00000801, "Back-to-back 1");
    verify_read(32'h00000800, 32'h1000000F, "Back-to-back 2");
    verify_read(32'h00000404, 32'h12340007, "Back-to-back 3");
    
    // Test 9: Response delay handling
    $display("\n=== Test 9: Response Delay Handling ===");
    fork
        begin
            memory_read(32'h00000400, received_data);
            verify_result(received_data, 32'h00000801, "Delayed response");
        end
        begin
            // Add some delay before accepting response
            wait(mem_resp_valid_o);
            repeat(3) @(posedge clk);
        end
    join
    
    //Test 10: Rapid requests
    $display("\n=== Test 10: Rapid Sequential Requests ===");
    
    rapid_addresses[0] = 32'h00000000; rapid_expected[0] = 32'h00000000;
    rapid_addresses[1] = 32'h00000400; rapid_expected[1] = 32'h00000801;
    rapid_addresses[2] = 32'h00000404; rapid_expected[2] = 32'h12340007;
    rapid_addresses[3] = 32'h00000800; rapid_expected[3] = 32'h1000000F;
    rapid_addresses[4] = 32'h00000804; rapid_expected[4] = 32'h1100000F;
    
    for (i = 0; i < 5; i = i + 1) begin
        memory_read(rapid_addresses[i], received_data);
        if (received_data !== rapid_expected[i]) begin
            $display("ERROR: Rapid test %d failed. addr=0x%08h, exp=0x%08h, got=0x%08h", 
                     i, rapid_addresses[i], rapid_expected[i], received_data);
            test_failed = test_failed + 1;
        end else begin
            $display("PASS: Rapid test %d: addr=0x%08h -> 0x%08h", 
                     i, rapid_addresses[i], received_data);
            test_passed = test_passed + 1;
        end
    end
    
    // Test 11: State machine robustness
    $display("\n=== Test 11: State Machine Robustness ===");
    
    // Send request but delay response acceptance
    @(posedge clk);
    mem_req_valid_i = 1'b1;
    mem_addr_i = 32'h00000400;
    @(posedge clk);
    mem_req_valid_i = 1'b0;
    
    // Wait for response but don't accept immediately
    wait(mem_resp_valid_o);
    repeat(5) @(posedge clk); // Wait several cycles
    
    // Now accept the response
    if (mem_data_o == 32'h00000801) begin
        $display("PASS: State machine handled delayed acceptance correctly");
        test_passed = test_passed + 1;
    end else begin
        $display("ERROR: State machine failed delayed acceptance test");
        test_failed = test_failed + 1;
    end
    
    mem_resp_ready_i = 1'b1;
    @(posedge clk);
    mem_resp_ready_i = 1'b0;
    @(posedge clk);
    
    // Final comprehensive test
    $display("\n=== Test 12: Comprehensive Address Test ===");
    
    test_addresses[0] = 32'h00000000; expected_values[0] = 32'h00000000;
    test_addresses[1] = 32'h00000400; expected_values[1] = 32'h00000801;
    test_addresses[2] = 32'h00000404; expected_values[2] = 32'h12340007;
    test_addresses[3] = 32'h00000408; expected_values[3] = 32'h00000000;
    test_addresses[4] = 32'h00000800; expected_values[4] = 32'h1000000F;
    test_addresses[5] = 32'h00000804; expected_values[5] = 32'h1100000F;
    test_addresses[6] = 32'h00000808; expected_values[6] = 32'h12000007;
    test_addresses[7] = 32'h0000080C; expected_values[7] = 32'h00000000;
    test_addresses[8] = 32'h00000FFC; expected_values[8] = 32'h00000000;
    test_addresses[9] = 32'h00001000; expected_values[9] = 32'h00000000;
    
    for (i = 0; i < 10; i = i + 1) begin
        memory_read(test_addresses[i], received_data);
        if (received_data !== expected_values[i]) begin
            $display("ERROR: Comprehensive test %d failed", i);
            $display("  addr=0x%08h, exp=0x%08h, got=0x%08h", 
                     test_addresses[i], expected_values[i], received_data);
            test_failed = test_failed + 1;
        end else begin
            $display("PASS: Comprehensive test %d", i);
            test_passed = test_passed + 1;
        end
    end
    
    // Final report
    #100;
    $display("\n========================================");
    $display("Memory Test Summary:");
    $display("  Tests Passed: %d", test_passed);
    $display("  Tests Failed: %d", test_failed);
    
    if (test_failed == 0) begin
        $display("  ALL TESTS PASSED!");
    end else begin
        $display("  SOME TESTS FAILED!");
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

// 状态监控
always @(posedge clk) begin
    $display("Time: %0t, State: %s, req_valid=%b, req_ready=%b, resp_valid=%b, resp_ready=%b", 
             $time,
             (dut.state == 2'b00) ? "IDLE" :
             (dut.state == 2'b01) ? "READ_ACCESS" :
             (dut.state == 2'b10) ? "RESPOND" : "UNKNOWN",
             mem_req_valid_i, mem_req_ready_o, mem_resp_valid_o, mem_resp_ready_i);
end

endmodule

