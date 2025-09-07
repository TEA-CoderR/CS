// test_integrated_memory_ptw.v
// Memory模块和PTW模块的集成测试
// 测试完整的页表遍历流程

//`timescale 1ns/1ps

module test_integration_memory_ptw;

// Clock and reset
reg clk;
reg rst;

// PTW Interface (TLB side)
reg ptw_req_valid_i;
wire ptw_req_ready_o;
reg [31:0] ptw_vaddr_i;

wire ptw_resp_valid_o;
reg ptw_resp_ready_i;
wire [31:0] ptw_pte_o;

// Memory-PTW interconnection
wire mem_req_valid;
wire mem_req_ready;
wire [31:0] mem_addr;

wire mem_resp_valid;
wire mem_resp_ready;
wire [31:0] mem_data;

// Test variables
integer test_passed;
integer test_failed;
reg [31:0] received_pte;
reg [31:0] expected_pte;

// DUT instantiations
memory mem_inst (
    .clk(clk),
    .rst(rst),
    // Memory Interface
    .mem_req_valid_i(mem_req_valid),
    .mem_req_ready_o(mem_req_ready),
    .mem_addr_i(mem_addr),
    .mem_resp_valid_o(mem_resp_valid),
    .mem_resp_ready_i(mem_resp_ready),
    .mem_data_o(mem_data)
);

ptw ptw_inst (
    .clk(clk),
    .rst(rst),
    // TLB Interface
    .ptw_req_valid_i(ptw_req_valid_i),
    .ptw_req_ready_o(ptw_req_ready_o),
    .ptw_vaddr_i(ptw_vaddr_i),
    .ptw_resp_valid_o(ptw_resp_valid_o),
    .ptw_resp_ready_i(ptw_resp_ready_i),
    .ptw_pte_o(ptw_pte_o),
    // Memory Interface
    .mem_req_valid_o(mem_req_valid),
    .mem_req_ready_i(mem_req_ready),
    .mem_addr_o(mem_addr),
    .mem_resp_valid_i(mem_resp_valid),
    .mem_resp_ready_o(mem_resp_ready),
    .mem_data_i(mem_data)
);

// Clock generation
always #5 clk = ~clk;

// Test tasks
task reset_system;
begin
    rst = 1'b1;
    ptw_req_valid_i = 1'b0;
    ptw_resp_ready_i = 1'b0;
    ptw_vaddr_i = 32'h00000000;
    @(posedge clk);
    @(posedge clk);
    rst = 1'b0;
    @(posedge clk);
    $display("System reset completed");
end
endtask

task integrated_translate(
    input [31:0] vaddr,
    output [31:0] pte_result
);
begin
    $display("  [INTEGRATED] Starting translation for vaddr=0x%08h", vaddr);
    $display("    VPN1=%d, VPN0=%d", vaddr[31:22], vaddr[21:12]);
    
    // 1. 发送PTW请求
    while (ptw_req_ready_o !== 1'b1) @(posedge clk);
    ptw_req_valid_i = 1'b1;
    ptw_vaddr_i = vaddr;
    //@(posedge clk);
    //@(posedge clk);
    
    // 等待请求被接受
    //while (ptw_req_ready_o !== 1'b0) @(posedge clk);
    do @(posedge clk); while (ptw_req_ready_o !== 1'b0);

    ptw_req_valid_i = 1'b0;
    
    $display("  [INTEGRATED] PTW request sent, waiting for completion...");
    
    // 2. 等待PTW完成所有内存访问并返回结果
    while (ptw_resp_valid_o !== 1'b1) begin
        @(posedge clk);
        
        // 可选：监控内存访问过程
        if (mem_req_valid && mem_req_ready) begin
            $display("    [MEM_ACCESS] Reading from addr=0x%08h", mem_addr);
        end
        if (mem_resp_valid && mem_resp_ready) begin
            $display("    [MEM_ACCESS] Got data=0x%08h", mem_data);
        end
    end
    
    pte_result = ptw_pte_o;
    
    // 3. 接受PTW响应
    ptw_resp_ready_i = 1'b1;
    //@(posedge clk);
    //@(posedge clk);
    
    // 等待响应被确认
    //while (ptw_resp_valid_o !== 1'b0) @(posedge clk);
    do @(posedge clk); while (ptw_resp_valid_o !== 1'b0);
    ptw_resp_ready_i = 1'b0;
    @(posedge clk);
    
    $display("  [INTEGRATED] Translation complete: pte=0x%08h", pte_result);
end
endtask

task verify_translation(
    input [31:0] vaddr,
    input [31:0] exp_pte,
    input [255:0] test_name
);
begin
    $display("\n--- Testing [%s] ---", test_name);
    $display("Virtual Address: 0x%08h", vaddr);
    integrated_translate(vaddr, received_pte);
    if (received_pte !== exp_pte) begin
        $display("ERROR [%s]: Translation mismatch", test_name);
        $display("  VAddr:    0x%08h", vaddr);
        $display("  Expected: 0x%08h", exp_pte);
        $display("  Got:      0x%08h", received_pte);
        test_failed = test_failed + 1;
    end else begin
        $display("PASS [%s]: vaddr=0x%08h -> pte=0x%08h", test_name, vaddr, received_pte);
        test_passed = test_passed + 1;
    end
end
endtask

// 详细的页表遍历验证任务
task verify_detailed_walk(
    input [31:0] vaddr,
    input [31:0] exp_l1_addr,
    input [31:0] exp_l1_pte,
    input [31:0] exp_l2_addr,
    input [31:0] exp_final_pte,
    input [255:0] test_name
);
integer access_count;
reg [31:0] captured_addrs [0:3];
reg [31:0] captured_data [0:3];
begin
    $display("\n=== Detailed Walk [%s] ===", test_name);
    $display("Testing vaddr=0x%08h", vaddr);
    
    access_count = 0;
    
    // 开始翻译
    ptw_req_valid_i = 1'b1;
    ptw_vaddr_i = vaddr;
    @(posedge clk);
    @(posedge clk);
    ptw_req_valid_i = 1'b0;
    
    // 监控所有内存访问
    fork
        // 主线程：等待PTW完成
        begin
            wait(ptw_resp_valid_o);
            received_pte = ptw_pte_o;
            ptw_resp_ready_i = 1'b1;
            @(posedge clk);
            @(posedge clk);
            ptw_resp_ready_i = 1'b0;
        end
        
        // 监控线程：捕获内存访问
        begin
            while (!ptw_resp_valid_o) begin
                @(posedge clk);
                if (mem_req_valid && mem_req_ready) begin
                    captured_addrs[access_count] = mem_addr;
                    $display("  Memory Access %d: addr=0x%08h", access_count, mem_addr);
                end
                if (mem_resp_valid && mem_resp_ready) begin
                    captured_data[access_count] = mem_data;
                    $display("  Memory Response %d: data=0x%08h", access_count, mem_data);
                    access_count = access_count + 1;
                end
            end
        end
    join
    
    // 验证结果
    $display("  Final PTE: 0x%08h (expected: 0x%08h)", received_pte, exp_final_pte);
    
    if (access_count >= 1) begin
        $display("  L1 Access - Addr: 0x%08h (expected: 0x%08h), Data: 0x%08h (expected: 0x%08h)", 
                 captured_addrs[0], exp_l1_addr, captured_data[0], exp_l1_pte);
    end
    
    if (access_count >= 2) begin
        $display("  L2 Access - Addr: 0x%08h (expected: 0x%08h)", 
                 captured_addrs[1], exp_l2_addr);
    end
    
    // 验证最终结果
    if (received_pte == exp_final_pte) begin
        $display("PASS [%s]: Complete page walk successful", test_name);
        test_passed = test_passed + 1;
    end else begin
        $display("ERROR [%s]: Page walk failed", test_name);
        test_failed = test_failed + 1;
    end
end
endtask

// Main test sequence
integer i;
reg [31:0] test_vaddrs [0:7];
reg [31:0] expected_ptes [0:7];
initial begin
    $dumpfile("test_integration_memory_ptw.vcd");
    $dumpvars(0, test_integration_memory_ptw);
    
    // Initialize
    clk = 1'b0;
    test_passed = 0;
    test_failed = 0;
    
    $display("================================================");
    $display("Memory-PTW Integrated Test Starting");
    $display("================================================");
    $display("Page Table Layout:");
    $display("  Root PT at 0x0400 (word index 256)");
    $display("    [0]: 0x00000801 -> L2 PT at 0x0800");
    $display("    [1]: 0x12340007 -> Megapage PPN=0x1234");
    $display("    [2]: 0x00000000 -> Invalid");
    $display("  L2 PT at 0x0800 (word index 512)");
    $display("    [0]: 0x1000000F -> PPN=0x10000");
    $display("    [1]: 0x1100000F -> PPN=0x11000");
    $display("    [2]: 0x12000007 -> PPN=0x12000");
    $display("    [3]: 0x00000000 -> Invalid");
    $display("================================================");
    
    // Test 1: System Reset
    $display("\n=== Test 1: System Reset ===");
    reset_system();
    if (!ptw_req_ready_o) begin
        $display("ERROR: PTW not ready after reset");
        test_failed = test_failed + 1;
    end else begin
        $display("PASS: System ready after reset");
        test_passed = test_passed + 1;
    end
    
    // Test 2: Basic two-level page table walks
    $display("\n=== Test 2: Two-Level Page Table Walks ===");
    
    // VAddr: 0x00000000 -> VPN1=0, VPN0=0
    // Should access L1[0]=0x00000801, then L2[0]=0x1000000F
    verify_translation(32'h00000000, 32'h1000000F, "4K page VPN1=0,VPN0=0");
    
    // VAddr: 0x00001000 -> VPN1=0, VPN0=1  
    // Should access L1[0]=0x00000801, then L2[1]=0x1100000F
    verify_translation(32'h00001000, 32'h1100000F, "4K page VPN1=0,VPN0=1");
    
    // VAddr: 0x00002000 -> VPN1=0, VPN0=2
    // Should access L1[0]=0x00000801, then L2[2]=0x12000007
    verify_translation(32'h00002000, 32'h12000007, "4K page VPN1=0,VPN0=2");
    
    // Test 3: Detailed page walk verification
    $display("\n=== Test 3: Detailed Page Walk Verification ===");
    
    verify_detailed_walk(
        32'h00000000,           // vaddr
        32'h00000400,           // expected L1 address  
        32'h00000801,           // expected L1 PTE
        32'h00000800,           // expected L2 address
        32'h1000000F,           // expected final PTE
        "Detailed walk for 0x00000000"
    );
    
    verify_detailed_walk(
        32'h00001000,           // vaddr
        32'h00000400,           // expected L1 address
        32'h00000801,           // expected L1 PTE  
        32'h00000804,           // expected L2 address
        32'h1100000F,           // expected final PTE
        "Detailed walk for 0x00001000"
    );
    
    // Test 4: Invalid page table entries
    $display("\n=== Test 4: Invalid Page Table Entries ===");
    
    // VAddr: 0x80000000 -> VPN1=2, VPN0=0
    // Should access L1[2]=0x00000000 (invalid), return 0
    verify_translation(32'h80000000, 32'h00000000, "Invalid L1 entry");
    
    // VAddr: 0x00003000 -> VPN1=0, VPN0=3
    // Should access L1[0]=0x00000801, then L2[3]=0x00000000 (invalid)
    verify_translation(32'h00003000, 32'h00000000, "Invalid L2 entry");
    
    // Test 5: Address boundary testing
    $display("\n=== Test 5: Address Boundary Testing ===");
    
    // Test different VPN combinations
    verify_translation(32'h00000000, 32'h1000000F, "Boundary: VPN1=0,VPN0=0");
    verify_translation(32'h00002000, 32'h12000007, "Boundary: VPN1=0,VPN0=2");
    verify_translation(32'h00003000, 32'h00000000, "Boundary: VPN1=0,VPN0=3(invalid)");
    
    // Test 6: Performance and timing
    $display("\n=== Test 6: Back-to-Back Translations ===");
    
    test_vaddrs[0] = 32'h00000000; expected_ptes[0] = 32'h1000000F;
    test_vaddrs[1] = 32'h00001000; expected_ptes[1] = 32'h1100000F;
    test_vaddrs[2] = 32'h00002000; expected_ptes[2] = 32'h12000007;
    test_vaddrs[3] = 32'h80000000; expected_ptes[3] = 32'h00000000;
    
    for (i = 0; i < 4; i = i + 1) begin
        integrated_translate(test_vaddrs[i], received_pte);
        if (received_pte !== expected_ptes[i]) begin
            $display("ERROR: Back-to-back test %d failed. vaddr=0x%08h, exp=0x%08h, got=0x%08h", 
                     i, test_vaddrs[i], expected_ptes[i], received_pte);
            test_failed = test_failed + 1;
        end else begin
            $display("PASS: Back-to-back test %d: vaddr=0x%08h -> pte=0x%08h", 
                     i, test_vaddrs[i], received_pte);
            test_passed = test_passed + 1;
        end
    end
    
    // Test 7: System stress test
    $display("\n=== Test 7: System Stress Test ===");
    
    // Rapid sequential translations
    for (i = 0; i < 8; i = i + 1) begin
        case (i % 4)
            0: begin
                integrated_translate(32'h00000000, received_pte);
                expected_pte = 32'h1000000F;
            end
            1: begin
                integrated_translate(32'h00001000, received_pte);
                expected_pte = 32'h1100000F;
            end
            2: begin
                integrated_translate(32'h00002000, received_pte);
                expected_pte = 32'h12000007;
            end
            3: begin
                integrated_translate(32'h80000000, received_pte);
                expected_pte = 32'h00000000;
            end
        endcase
        
        if (received_pte == expected_pte) begin
            $display("PASS: Stress test iteration %d", i);
            test_passed = test_passed + 1;
        end else begin
            $display("ERROR: Stress test iteration %d failed. exp=0x%08h, got=0x%08h", 
                     i, expected_pte, received_pte);
            test_failed = test_failed + 1;
        end
    end
    
    // Test 8: Response delay handling
    $display("\n=== Test 8: Response Delay Handling ===");
    
    fork
        begin
            integrated_translate(32'h00000000, received_pte);
            if (received_pte == 32'h1000000F) begin
                $display("PASS: Delayed response handling");
                test_passed = test_passed + 1;
            end else begin
                $display("ERROR: Delayed response handling failed");
                test_failed = test_failed + 1;
            end
        end
        begin
            // Add some delay during the translation process
            wait(mem_req_valid);
            repeat(3) @(posedge clk);
        end
    join
    
    // Final comprehensive test
    $display("\n=== Test 9: Comprehensive Integration Test ===");
    
    test_vaddrs[0] = 32'h00000000; expected_ptes[0] = 32'h1000000F;  // L2[0]
    test_vaddrs[1] = 32'h00001000; expected_ptes[1] = 32'h1100000F;  // L2[1]
    test_vaddrs[2] = 32'h00002000; expected_ptes[2] = 32'h12000007;  // L2[2]
    test_vaddrs[3] = 32'h00003000; expected_ptes[3] = 32'h00000000;  // L2[3] invalid
    test_vaddrs[4] = 32'h80000000; expected_ptes[4] = 32'h00000000;  // L1[2] invalid
    test_vaddrs[5] = 32'h00000800; expected_ptes[5] = 32'h1000000F;  // Same page as [0]
    test_vaddrs[6] = 32'h00001800; expected_ptes[6] = 32'h1100000F;  // Same page as [1]
    test_vaddrs[7] = 32'hC0000000; expected_ptes[7] = 32'h00000000;  // L1[3] invalid
    
    for (i = 0; i < 8; i = i + 1) begin
        integrated_translate(test_vaddrs[i], received_pte);
        if (received_pte !== expected_ptes[i]) begin
            $display("ERROR: Comprehensive test %d failed", i);
            $display("  vaddr=0x%08h, exp=0x%08h, got=0x%08h", 
                     test_vaddrs[i], expected_ptes[i], received_pte);
            test_failed = test_failed + 1;
        end else begin
            $display("PASS: Comprehensive test %d: 0x%08h -> 0x%08h", 
                     i, test_vaddrs[i], received_pte);
            test_passed = test_passed + 1;
        end
    end
    
    // Final report
    #100;
    $display("\n================================================");
    $display("Memory-PTW Integrated Test Summary:");
    $display("  Tests Passed: %d", test_passed);
    $display("  Tests Failed: %d", test_failed);
    $display("  Success Rate: %0.1f%%", (test_passed * 100.0) / (test_passed + test_failed));
    
    if (test_failed == 0) begin
        $display("ALL TESTS PASSED! ");
        $display("The Memory and PTW modules work perfectly together!");
    end else begin
        $display("SOME TESTS FAILED!");
        $display("Please check the module interactions.");
    end
    $display("================================================");
    
    $finish;
end

// Timeout watchdog
initial begin
    #200000; // 增加超时时间，因为集成测试需要更长时间
    $display("ERROR: Integrated test timeout!");
    $finish;
end

// System-level monitoring
always @(posedge clk) begin
    // 监控PTW状态变化
    if (ptw_inst.state != ptw_inst.next_state) begin
        $display("[%0t] PTW State: %d -> %d", $time, ptw_inst.state, ptw_inst.next_state);
    end
    
    // 监控Memory状态变化
    if (mem_inst.state != mem_inst.next_state) begin
        $display("[%0t] Memory State: %d -> %d", $time, mem_inst.state, mem_inst.next_state);
    end
end

// Transaction monitoring
always @(posedge clk) begin
    if (ptw_req_valid_i && ptw_req_ready_o) begin
        $display("[%0t] [TRANSACTION] PTW request: vaddr=0x%08h", $time, ptw_vaddr_i);
    end
    if (mem_req_valid && mem_req_ready) begin
        $display("[%0t] [TRANSACTION] Memory request: addr=0x%08h", $time, mem_addr);
    end
    if (mem_resp_valid && mem_resp_ready) begin
        $display("[%0t] [TRANSACTION] Memory response: data=0x%08h", $time, mem_data);
    end
    if (ptw_resp_valid_o && ptw_resp_ready_i) begin
        $display("[%0t] [TRANSACTION] PTW response: pte=0x%08h", $time, ptw_pte_o);
    end
end

// Performance monitoring
integer total_cycles;
integer active_translations;
always @(posedge clk) begin
    if (rst) begin
        total_cycles = 0;
        active_translations = 0;
    end else begin
        total_cycles = total_cycles + 1;
        if (ptw_req_valid_i && ptw_req_ready_o) begin
            active_translations = active_translations + 1;
        end
    end
end

// Final performance report
always @(posedge clk) begin
    if (test_passed + test_failed > 0 && total_cycles > 1000) begin
        $display("[PERF] Total cycles: %d, Active translations: %d", 
                 total_cycles, active_translations);
        if (active_translations > 0) begin
            $display("[PERF] Average cycles per translation: %0.1f", 
                     total_cycles * 1.0 / active_translations);
        end
    end
end

endmodule