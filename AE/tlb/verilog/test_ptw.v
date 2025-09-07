// // test_ptw.v
// // 简化的PTW调试测试

// module test_ptw;

// // Clock and reset
// reg clk;
// reg rst;

// // PTW Interface
// reg ptw_req_valid_i;
// wire ptw_req_ready_o;
// reg [31:0] ptw_vaddr_i;
// wire ptw_resp_valid_o;
// reg ptw_resp_ready_i;
// wire [31:0] ptw_pte_o;

// // Memory Interface  
// wire mem_req_valid_o;
// reg mem_req_ready_i;
// wire [31:0] mem_addr_o;
// reg mem_resp_valid_i;
// wire mem_resp_ready_o;
// reg [31:0] mem_data_i;

// // DUT instantiation
// ptw dut (
//     .clk(clk),
//     .rst(rst),
//     .ptw_req_valid_i(ptw_req_valid_i),
//     .ptw_req_ready_o(ptw_req_ready_o),
//     .ptw_vaddr_i(ptw_vaddr_i),
//     .ptw_resp_valid_o(ptw_resp_valid_o),
//     .ptw_resp_ready_i(ptw_resp_ready_i),
//     .ptw_pte_o(ptw_pte_o),
//     .mem_req_valid_o(mem_req_valid_o),
//     .mem_req_ready_i(mem_req_ready_i),
//     .mem_addr_o(mem_addr_o),
//     .mem_resp_valid_i(mem_resp_valid_i),
//     .mem_resp_ready_o(mem_resp_ready_o),
//     .mem_data_i(mem_data_i)
// );

// // Clock generation
// always #5 clk = ~clk;

// // 简化的内存模型 - 立即响应
// always @(posedge clk) begin
//     if (rst) begin
//         mem_req_ready_i <= 1'b1;
//         mem_resp_valid_i <= 1'b0;
//         mem_data_i <= 32'h00000000;
//     end else begin
//         // 立即接受所有内存请求
//         mem_req_ready_i <= 1'b1;
        
//         // 如果有内存请求，下个周期给响应
//         if (mem_req_valid_o && mem_req_ready_i) begin
//             $display("[MEM_MODEL] Request received: addr=0x%08h", mem_addr_o);
            
//             // 根据地址返回预设数据
//             if (mem_addr_o == 32'h00000400) begin // L1[0] - 根页表第0项
//                 mem_data_i <= 32'h00000801; // 指向L2表@0x800
//                 $display("[MEM_MODEL] Returning L1[0] = 0x00000801");
//             end else if (mem_addr_o == 32'h00000800) begin // L2[0] - L2页表第0项
//                 mem_data_i <= 32'h1000000F; // PPN=0x10000, V|R|W|X
//                 $display("[MEM_MODEL] Returning L2[0] = 0x1000000F");
//             end else if (mem_addr_o == 32'h00000804) begin // L2[1] 
//                 mem_data_i <= 32'h1100000F; 
//                 $display("[MEM_MODEL] Returning L2[1] = 0x1100000F");
//             end else begin
//                 mem_data_i <= 32'h00000000;
//                 $display("[MEM_MODEL] Unknown address 0x%08h, returning 0", mem_addr_o);
//             end
//             mem_resp_valid_i <= 1'b1;
//         end else if (mem_resp_ready_o) begin
//             mem_resp_valid_i <= 1'b0;
//         end
//     end
// end

// // Test sequence
// initial begin
//     clk = 1'b0;
//     rst = 1'b1;
//     ptw_req_valid_i = 1'b0;
//     ptw_resp_ready_i = 1'b0;
//     ptw_vaddr_i = 32'h00000000;
    
//     $display("=== PTW Debug Test ===");
    
//     // Reset
//     repeat(3) @(posedge clk);
//     rst = 1'b0;
//     @(posedge clk);
//     $display("Reset completed");
    
//     // 检查初始状态
//     $display("Initial state: ptw_req_ready_o=%b", ptw_req_ready_o);
    
//     // 发送请求
//     $display("Sending PTW request for vaddr=0x00000000");
//     ptw_req_valid_i = 1'b1;
//     ptw_vaddr_i = 32'h00000000;
//     @(posedge clk);
//     @(posedge clk);
//     ptw_req_valid_i = 1'b0;
//     $display("Request sent");
    
//     // 等待并观察
//     repeat(20) begin
//         @(posedge clk);
//         $display("Cycle %0t: mem_req_valid=%b, mem_addr=0x%08h, ptw_resp_valid=%b", 
//                  $time, mem_req_valid_o, mem_addr_o, ptw_resp_valid_o);
//     end
    
//     $display("=== Test completed ===");
//     $finish;
// end

// // 状态监控 - 如果PTW有状态信号的话
// always @(posedge clk) begin
//     // 监控所有信号变化
//     if (ptw_req_valid_i && ptw_req_ready_o)
//         $display("[MONITOR] PTW request accepted at %0t", $time);
//     if (mem_req_valid_o && mem_req_ready_i)
//         $display("[MONITOR] Memory request sent at %0t: addr=0x%08h", $time, mem_addr_o);
//     if (mem_resp_valid_i && mem_resp_ready_o)
//         $display("[MONITOR] Memory response received at %0t: data=0x%08h", $time, mem_data_i);
//     if (ptw_resp_valid_o && ptw_resp_ready_i)
//         $display("[MONITOR] PTW response sent at %0t: pte=0x%08h", $time, ptw_pte_o);
// end

// // 超时保护
// initial begin
//     #1000;
//     $display("TIMEOUT: Test took too long");
//     $finish;
// end

// endmodule



// // debug_test_ptw.v
// // 简化的PTW调试测试

// module debug_test_ptw;

// // Clock and reset
// reg clk;
// reg rst;

// // PTW Interface
// reg ptw_req_valid_i;
// wire ptw_req_ready_o;
// reg [31:0] ptw_vaddr_i;
// wire ptw_resp_valid_o;
// reg ptw_resp_ready_i;
// wire [31:0] ptw_pte_o;

// // Memory Interface  
// wire mem_req_valid_o;
// reg mem_req_ready_i;
// wire [31:0] mem_addr_o;
// reg mem_resp_valid_i;
// wire mem_resp_ready_o;
// reg [31:0] mem_data_i;

// // DUT instantiation
// ptw dut (
//     .clk(clk),
//     .rst(rst),
//     .ptw_req_valid_i(ptw_req_valid_i),
//     .ptw_req_ready_o(ptw_req_ready_o),
//     .ptw_vaddr_i(ptw_vaddr_i),
//     .ptw_resp_valid_o(ptw_resp_valid_o),
//     .ptw_resp_ready_i(ptw_resp_ready_i),
//     .ptw_pte_o(ptw_pte_o),
//     .mem_req_valid_o(mem_req_valid_o),
//     .mem_req_ready_i(mem_req_ready_i),
//     .mem_addr_o(mem_addr_o),
//     .mem_resp_valid_i(mem_resp_valid_i),
//     .mem_resp_ready_o(mem_resp_ready_o),
//     .mem_data_i(mem_data_i)
// );

// // Clock generation
// always #5 clk = ~clk;

// // 简化的内存模型 - 立即响应
// always @(posedge clk) begin
//     if (rst) begin
//         mem_req_ready_i <= 1'b1;
//         mem_resp_valid_i <= 1'b0;
//         mem_data_i <= 32'h00000000;
//     end else begin
//         // 立即接受所有内存请求
//         mem_req_ready_i <= 1'b1;
        
//         // 如果有内存请求，下个周期给响应
//         if (mem_req_valid_o && mem_req_ready_i) begin
//             $display("[MEM_MODEL] Request received: addr=0x%08h", mem_addr_o);
            
//             // 根据地址返回预设数据
//             if (mem_addr_o == 32'h00000400) begin // L1[0]
//                 mem_data_i <= 32'h00000801; // 指向L2表@0x800
//                 $display("[MEM_MODEL] Returning L1[0] = 0x00000801");
//             end else if (mem_addr_o == 32'h00000800) begin // L2[0]  
//                 mem_data_i <= 32'h1000000F; // PPN=0x10000, V|R|W|X
//                 $display("[MEM_MODEL] Returning L2[0] = 0x1000000F");
//             end else begin
//                 mem_data_i <= 32'h00000000;
//                 $display("[MEM_MODEL] Unknown address, returning 0");
//             end
//             mem_resp_valid_i <= 1'b1;
//         end else if (mem_resp_ready_o) begin
//             mem_resp_valid_i <= 1'b0;
//         end
//     end
// end

// // Test sequence
// initial begin
//     clk = 1'b0;
//     rst = 1'b1;
//     ptw_req_valid_i = 1'b0;
//     ptw_resp_ready_i = 1'b0;
//     ptw_vaddr_i = 32'h00000000;
    
//     $display("=== PTW Debug Test ===");
    
//     // Reset
//     repeat(3) @(posedge clk);
//     rst = 1'b0;
//     @(posedge clk);
//     $display("Reset completed");
    
//     // 检查初始状态
//     $display("Initial state: ptw_req_ready_o=%b", ptw_req_ready_o);
    
//     // 发送请求
//     $display("Sending PTW request for vaddr=0x00000000");
//     ptw_req_valid_i = 1'b1;
//     ptw_vaddr_i = 32'h00000000;
//     @(posedge clk);
//     @(posedge clk);
//     ptw_req_valid_i = 1'b0;
//     $display("Request sent");
    
//     // 等待并观察
//     repeat(20) begin
//         @(posedge clk);
//         $display("Cycle %0t: mem_req_valid=%b, mem_addr=0x%08h, ptw_resp_valid=%b", 
//                  $time, mem_req_valid_o, mem_addr_o, ptw_resp_valid_o);
//     end
    
//     $display("=== Test completed ===");
//     $finish;
// end

// // 状态监控 - 如果PTW有状态信号的话
// always @(posedge clk) begin
//     // 监控所有信号变化
//     if (ptw_req_valid_i && ptw_req_ready_o)
//         $display("[MONITOR] PTW request accepted at %0t", $time);
//     if (mem_req_valid_o && mem_req_ready_i)
//         $display("[MONITOR] Memory request sent at %0t: addr=0x%08h", $time, mem_addr_o);
//     if (mem_resp_valid_i && mem_resp_ready_o)
//         $display("[MONITOR] Memory response received at %0t: data=0x%08h", $time, mem_data_i);
//     if (ptw_resp_valid_o && ptw_resp_ready_i)
//         $display("[MONITOR] PTW response sent at %0t: pte=0x%08h", $time, ptw_pte_o);
// end

// // 超时保护
// initial begin
//     #1000;
//     $display("TIMEOUT: Test took too long");
//     $finish;
// end

// endmodule




// test_ptw.v
// PTW 模块单元测试

//`timescale 1ns/1ps

module test_ptw;

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

// Memory Interface (PTW to Memory)
wire mem_req_valid_o;
reg mem_req_ready_i;
wire [31:0] mem_addr_o;

reg mem_resp_valid_i;
wire mem_resp_ready_o;
reg [31:0] mem_data_i;

// Test variables
integer test_passed;
integer test_failed;
reg [31:0] received_pte;
reg [31:0] expected_pte;

// DUT instantiation
ptw dut (
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
    .mem_req_valid_o(mem_req_valid_o),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_addr_o(mem_addr_o),
    .mem_resp_valid_i(mem_resp_valid_i),
    .mem_resp_ready_o(mem_resp_ready_o),
    .mem_data_i(mem_data_i)
);

// Clock generation
always #5 clk = ~clk;

// Memory simulation - 简化的内存模型
reg [31:0] sim_mem [0:1023];
initial begin
    integer i;
    // Initialize memory
    for (i = 0; i < 1024; i = i + 1) begin
        sim_mem[i] = 32'h00000000;
    end
    
    // 根页表在0x400 (word index 256)
    sim_mem[256 + 0] = 32'h00000801; // VPN[31:22]=0: 指向L2表@0x800, Valid
    sim_mem[256 + 1] = 32'h12340007; // VPN[31:22]=1: Megapage PPN=0x1234, V|R|W
    sim_mem[256 + 2] = 32'h00000000; // VPN[31:22]=2: Invalid entry
    
    // Level 2 页表在0x800 (word index 512)
    sim_mem[512 + 0] = 32'h1000000F; // VPN[21:12]=0: PPN=0x10000, V|R|W|X
    sim_mem[512 + 1] = 32'h1100000F; // VPN[21:12]=1: PPN=0x11000, V|R|W|X
    sim_mem[512 + 2] = 32'h12000007; // VPN[21:12]=2: PPN=0x12000, V|R|W
    sim_mem[512 + 3] = 32'h00000000; // VPN[21:12]=3: Invalid entry
end

// Memory response simulation
always @(posedge clk) begin
    if (rst) begin
        mem_resp_valid_i <= 1'b0;
        mem_data_i <= 32'h00000000;
        mem_req_ready_i <= 1'b1;
    end else begin
        if (mem_req_valid_o && mem_req_ready_i) begin
            // Memory request accepted, prepare response
            mem_req_ready_i <= 1'b0;
            @(posedge clk);
            
            // Send memory response
            if (mem_addr_o[31:2] < 1024) begin
                mem_data_i <= sim_mem[mem_addr_o[31:2]];
            end else begin
                mem_data_i <= 32'h00000000;
            end
            mem_resp_valid_i <= 1'b1;
            
            // Wait for response acceptance
            wait(mem_resp_ready_o);
            @(posedge clk);
            mem_resp_valid_i <= 1'b0;
            mem_req_ready_i <= 1'b1;
        end
    end
end

// Test tasks
task reset_dut;
begin
    rst = 1'b1;
    ptw_req_valid_i = 1'b0;
    ptw_resp_ready_i = 1'b0;
    ptw_vaddr_i = 32'h00000000;
    @(posedge clk);
    @(posedge clk);
    rst = 1'b0;
    @(posedge clk);
    $display("PTW reset completed");
end
endtask


task ptw_translate(
    input [31:0] vaddr,
    output [31:0] pte_result
);
begin
    $display("  [PTW] Starting translation for vaddr=0x%08h", vaddr);
    
    // 1. 发送PTW请求
    while (ptw_req_ready_o !== 1'b1) @(posedge clk);
    ptw_req_valid_i = 1'b1;
    ptw_vaddr_i = vaddr;
    @(posedge clk);
    @(posedge clk);
    ptw_req_valid_i = 1'b0;
    
    // 2. 等待PTW完成
    while (ptw_resp_valid_o !== 1'b1) @(posedge clk);
    pte_result = ptw_pte_o;
    
    // 3. 接受响应
    ptw_resp_ready_i = 1'b1;
    @(posedge clk);
    @(posedge clk);
    ptw_resp_ready_i = 1'b0;
    @(posedge clk);
    
    $display("  [PTW] Translation complete: pte=0x%08h", pte_result);
end
endtask

// task ptw_translate(
//     input [31:0] vaddr,
//     output [31:0] pte_result
// );
// begin
//     $display("  [TASK] Starting translation for vaddr=0x%08h", vaddr);
    
//     // Send PTW request
//     wait(ptw_req_ready_o);
//     $display("  [TASK] PTW ready, sending request");
//     ptw_req_valid_i = 1'b1;
//     ptw_vaddr_i = vaddr;
//     @(posedge clk);
//     @(posedge clk);
//     ptw_req_valid_i = 1'b0;
//     $display("  [TASK] Request sent, waiting for response");
    
//     // Wait for PTW response with timeout
//     fork
//         begin
//             wait(ptw_resp_valid_o);
//             $display("  [TASK] Response received");
//         end
//         begin
//             repeat(1000) @(posedge clk);
//             $display("  [TASK] WARNING: Long wait for PTW response");
//         end
//     join_any
    
//     if (ptw_resp_valid_o) begin
//         pte_result = ptw_pte_o;
//         ptw_resp_ready_i = 1'b1;
//         @(posedge clk);
//         @(posedge clk);
//         ptw_resp_ready_i = 1'b0;
//         @(posedge clk);
//         $display("  [TASK] Translation completed: 0x%08h -> 0x%08h", vaddr, pte_result);
//     end else begin
//         $display("  [TASK] ERROR: No response received");
//         pte_result = 32'hDEADBEEF; // Error indicator
//     end
// end
// endtask

task verify_result(
    input [31:0] got_pte,
    input [31:0] exp_pte,
    input [255:0] test_name
);
begin
    if (got_pte !== exp_pte) begin
        $display("ERROR [%s]: PTE mismatch", test_name);
        $display("  Expected: 0x%08h", exp_pte);
        $display("  Got:      0x%08h", got_pte);
        test_failed = test_failed + 1;
    end else begin
        $display("PASS [%s]: pte=0x%08h", test_name, got_pte);
        test_passed = test_passed + 1;
    end
end
endtask

task verify_translation(
    input [31:0] vaddr,
    input [31:0] exp_pte,
    input [255:0] test_name
);
begin
    $display("Testing [%s]: vaddr=0x%08h", test_name, vaddr);
    ptw_translate(vaddr, received_pte);
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
    $display("");
end
endtask

// Main test sequence
integer i;
reg [31:0] test_vaddrs [0:9];
reg [31:0] expected_ptes [0:9];
initial begin
    // Initialize
    clk = 1'b0;
    test_passed = 0;
    test_failed = 0;
    
    $display("========================================");
    $display("PTW Unit Test Starting");
    $display("========================================");
    
    // Test 1: Reset functionality
    $display("\n=== Test 1: Reset Functionality ===");
    reset_dut();
    if (!ptw_req_ready_o) begin
        $display("ERROR: PTW not ready after reset");
        test_failed = test_failed + 1;
    end else begin
        $display("PASS: PTW ready after reset");
        test_passed = test_passed + 1;
    end
    
    // Test 2: Two-level page table walk (normal 4K pages)
    $display("\n=== Test 2: Two-Level Page Table Walk ===");
    // VAddr: 0x00000000 -> VPN1=0, VPN0=0 -> Should access L1[0] then L2[0]
    verify_translation(32'h00000000, 32'h1000000F, "4K page - VPN1=0,VPN0=0");
    
    // VAddr: 0x00001000 -> VPN1=0, VPN0=1 -> Should access L1[0] then L2[1]  
    verify_translation(32'h00001000, 32'h1100000F, "4K page - VPN1=0,VPN0=1");
    
    // VAddr: 0x00002000 -> VPN1=0, VPN0=2 -> Should access L1[0] then L2[2]
    verify_translation(32'h00002000, 32'h12000007, "4K page - VPN1=0,VPN0=2");
    
    // Test 4: Invalid page table entries
    $display("\n=== Test 4: Invalid Page Table Entries ===");
    // VAddr: 0x80000000 -> VPN1=2, VPN0=0 -> Should access L1[2] (invalid)
    verify_translation(32'h80000000, 32'h00000000, "Invalid L1 entry");
    
    // VAddr: 0x00003000 -> VPN1=0, VPN0=3 -> Should access L1[0] then L2[3] (invalid)
    verify_translation(32'h00003000, 32'h00000000, "Invalid L2 entry");
    
    // Test 5: Address decomposition verification
    $display("\n=== Test 5: Address Decomposition Test ===");
    $display("Testing VPN extraction:");
    
    // Test different VPN combinations
    verify_translation(32'h00000000, 32'h1000000F, "VPN1=0, VPN0=0");    // 0x000_000_000
    
    // 修正地址计算
    verify_translation(32'h00001000, 32'h1100000F, "VPN1=0, VPN0=1");     // 0x000_001_000
    
    // Test 6: Edge cases
    $display("\n=== Test 6: Edge Cases ===");
    
    // Test maximum valid addresses within our page table range
    verify_translation(32'h00002000, 32'h12000007, "Last valid L2 entry");
    
    // Test 7: Back-to-back translations
    $display("\n=== Test 7: Back-to-Back Translations ===");
    verify_translation(32'h00000000, 32'h1000000F, "Back-to-back 1");
    verify_translation(32'h00001000, 32'h1100000F, "Back-to-back 2");
    
    // Test 8: Response delay handling  
    $display("\n=== Test 8: Response Delay Handling ===");
    fork
        begin
            ptw_translate(32'h00000000, received_pte);
            verify_result(received_pte, 32'h1000000F, "Delayed response");
        end
        begin
            // Add some delay before accepting response
            wait(ptw_resp_valid_o);
            repeat(3) @(posedge clk);
        end
    join
    
    // Test 9: Rapid translations
    $display("\n=== Test 9: Rapid Sequential Translations ===");
    
    test_vaddrs[0] = 32'h00000000; expected_ptes[0] = 32'h1000000F;  // 4K page
    test_vaddrs[1] = 32'h00001000; expected_ptes[1] = 32'h1100000F;  // 4K page
    test_vaddrs[2] = 32'h80000000; expected_ptes[2] = 32'h00000000;  // Invalid
    
    for (i = 0; i < 3; i = i + 1) begin
        ptw_translate(test_vaddrs[i], received_pte);
        if (received_pte !== expected_ptes[i]) begin
            $display("ERROR: Rapid test %d failed. vaddr=0x%08h, exp=0x%08h, got=0x%08h", 
                     i, test_vaddrs[i], expected_ptes[i], received_pte);
            test_failed = test_failed + 1;
        end else begin
            $display("PASS: Rapid test %d: vaddr=0x%08h -> pte=0x%08h", 
                     i, test_vaddrs[i], received_pte);
            test_passed = test_passed + 1;
        end
    end
    
    // Test 10: State machine robustness
    // $display("\n=== Test 10: State Machine Robustness ===");
    
    // // Send request but delay response acceptance
    // @(posedge clk);
    // ptw_req_valid_i = 1'b1;
    // ptw_vaddr_i = 32'h00000000;
    // @(posedge clk);
    // ptw_req_valid_i = 1'b0;
    
    // // Wait for response but don't accept immediately
    // wait(ptw_resp_valid_o);
    // repeat(5) @(posedge clk); // Wait several cycles
    
    // // Now accept the response
    // if (ptw_pte_o == 32'h1000000F) begin
    //     $display("PASS: State machine handled delayed acceptance correctly");
    //     test_passed = test_passed + 1;
    // end else begin
    //     $display("ERROR: State machine failed delayed acceptance test. Got: 0x%08h", ptw_pte_o);
    //     test_failed = test_failed + 1;
    // end
    
    // ptw_resp_ready_i = 1'b1;
    // @(posedge clk);
    // ptw_resp_ready_i = 1'b0;
    // @(posedge clk);
    
    // // Test 11: Comprehensive translation test
    // $display("\n=== Test 11: Comprehensive Translation Test ===");
    
    // test_vaddrs[0] = 32'h00000000; expected_ptes[0] = 32'h1000000F;  // L2[0]
    // test_vaddrs[1] = 32'h00001000; expected_ptes[1] = 32'h1100000F;  // L2[1]  
    // test_vaddrs[2] = 32'h00002000; expected_ptes[2] = 32'h12000007;  // L2[2]
    // test_vaddrs[3] = 32'h00003000; expected_ptes[3] = 32'h00000000;  // L2[3] invalid
    // test_vaddrs[4] = 32'h40000000; expected_ptes[4] = 32'h12340007;  // Megapage VPN0=0
    // test_vaddrs[5] = 32'h40001000; expected_ptes[5] = 32'h12341007;  // Megapage VPN0=1
    // test_vaddrs[6] = 32'h40002000; expected_ptes[6] = 32'h12342007;  // Megapage VPN0=2
    // test_vaddrs[7] = 32'h80000000; expected_ptes[7] = 32'h00000000;  // L1[2] invalid
    // test_vaddrs[8] = 32'hC0000000; expected_ptes[8] = 32'h00000000;  // L1[3] invalid
    // test_vaddrs[9] = 32'h00000800; expected_ptes[9] = 32'h1000000F;  // Same as [0], different offset
    
    // for (i = 0; i < 10; i = i + 1) begin
    //     ptw_translate(test_vaddrs[i], received_pte);
    //     if (received_pte !== expected_ptes[i]) begin
    //         $display("ERROR: Comprehensive test %d failed", i);
    //         $display("  vaddr=0x%08h, exp=0x%08h, got=0x%08h", 
    //                  test_vaddrs[i], expected_ptes[i], received_pte);
    //         test_failed = test_failed + 1;
    //     end else begin
    //         $display("PASS: Comprehensive test %d: 0x%08h -> 0x%08h", 
    //                  i, test_vaddrs[i], received_pte);
    //         test_passed = test_passed + 1;
    //     end
    // end
    
    // Final report
    #100;
    $display("\n========================================");
    $display("PTW Test Summary:");
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
    #100000;
    $display("ERROR: PTW test timeout!");
    $finish;
end

// Debug monitoring
always @(posedge clk) begin
    if (ptw_req_valid_i && ptw_req_ready_o) begin
        $display("  [DEBUG] PTW request: vaddr=0x%08h, VPN1=%d, VPN0=%d", 
                 ptw_vaddr_i, ptw_vaddr_i[31:22], ptw_vaddr_i[21:12]);
    end
    if (mem_req_valid_o && mem_req_ready_i) begin
        $display("  [DEBUG] Memory request: addr=0x%08h", mem_addr_o);
    end
    if (mem_resp_valid_i && mem_resp_ready_o) begin
        $display("  [DEBUG] Memory response: data=0x%08h", mem_data_i);
    end
    if (ptw_resp_valid_o && ptw_resp_ready_i) begin
        $display("  [DEBUG] PTW response: pte=0x%08h", ptw_pte_o);
    end
end

always @(posedge clk) begin
    if (dut.state != dut.next_state) begin
        $display("[%0t] PTW State: %d -> %d", $time, dut.state, dut.next_state);
    end
end

endmodule
