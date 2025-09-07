// // test_tlb_deep_debug.v
// // 深度调试TLB内部状态

// //`timescale 1ns/1ps
// `include "tlb_params.vh"

// module test_tlb_deep_debug;

// // Clock and reset
// reg clk;
// reg rst;

// // Processor Interface
// reg req_valid_i;
// wire req_ready_o;
// reg [31:0] vaddr_i;
// reg access_type_i;

// wire resp_valid_o;
// reg resp_ready_i;
// wire [31:0] paddr_o;
// wire hit_o;
// wire fault_o;

// // PTW Interface
// wire ptw_req_valid_o;
// reg ptw_req_ready_i;
// wire [31:0] ptw_vaddr_o;

// reg ptw_resp_valid_i;
// wire ptw_resp_ready_o;
// reg [31:0] ptw_pte_i;

// // DUT instantiation
// tlb dut (
//     .clk(clk),
//     .rst(rst),
//     .req_valid_i(req_valid_i),
//     .req_ready_o(req_ready_o),
//     .vaddr_i(vaddr_i),
//     .access_type_i(access_type_i),
//     .resp_valid_o(resp_valid_o),
//     .resp_ready_i(resp_ready_i),
//     .paddr_o(paddr_o),
//     .hit_o(hit_o),
//     .fault_o(fault_o),
//     .ptw_req_valid_o(ptw_req_valid_o),
//     .ptw_req_ready_i(ptw_req_ready_i),
//     .ptw_vaddr_o(ptw_vaddr_o),
//     .ptw_resp_valid_i(ptw_resp_valid_i),
//     .ptw_resp_ready_o(ptw_resp_ready_o),
//     .ptw_pte_i(ptw_pte_i)
// );

// // Clock generation
// always #5 clk = ~clk;

// // 深度监控 - 监控所有状态变化
// always @(posedge clk) begin
//     $display("[CYCLE %0d] =====================", $time/10);
    
//     // 输入信号状态
//     $display("[INPUT] req_valid=%b, req_ready=%b, vaddr=0x%08h, access=%b", 
//              req_valid_i, req_ready_o, vaddr_i, access_type_i);
//     $display("[INPUT] resp_valid=%b, resp_ready=%b", resp_valid_o, resp_ready_i);
//     $display("[INPUT] ptw_req_valid=%b, ptw_req_ready=%b, ptw_vaddr=0x%08h", 
//              ptw_req_valid_o, ptw_req_ready_i, ptw_vaddr_o);
//     $display("[INPUT] ptw_resp_valid=%b, ptw_resp_ready=%b, ptw_pte=0x%08h", 
//              ptw_resp_valid_i, ptw_resp_ready_o, ptw_pte_i);
    
//     // 输出信号状态
//     $display("[OUTPUT] paddr=0x%08h, hit=%b, fault=%b", paddr_o, hit_o, fault_o);
    
//     // TLB内部状态（如果可以访问的话）
//     // 这里需要根据您的TLB模块结构来调整
//     // 例如：
//     // $display("[INTERNAL] controller_state=%d", dut.controller.state);
//     // $display("[INTERNAL] lookup_hit=%b", dut.lookup.hit);
//     // $display("[INTERNAL] storage_write_en=%b", dut.storage.write_en);
    
//     $display("");
// end

// // 更详细的状态变化监控
// always @(*) begin
//     if (req_valid_i && req_ready_o)
//         $display("[EVENT] TLB Request Accepted: vaddr=0x%08h", vaddr_i);
    
//     if (resp_valid_o && resp_ready_i)
//         $display("[EVENT] TLB Response: paddr=0x%08h, hit=%b, fault=%b", paddr_o, hit_o, fault_o);
    
//     if (ptw_req_valid_o && ptw_req_ready_i)
//         $display("[EVENT] PTW Request: vaddr=0x%08h", ptw_vaddr_o);
    
//     if (ptw_resp_valid_i && ptw_resp_ready_o)
//         $display("[EVENT] PTW Response: pte=0x%08h", ptw_pte_i);
// end

// // 任务：等待并检查信号
// task wait_and_check_signals;
//     input [255:0] description;
// begin
//     $display("\n[WAIT] %s", description);
//     @(posedge clk);
//     $display("[CHECK] After %s:", description);
//     $display("  req_ready_o = %b", req_ready_o);
//     $display("  resp_valid_o = %b", resp_valid_o);
//     $display("  ptw_req_valid_o = %b", ptw_req_valid_o);
//     $display("  ptw_resp_ready_o = %b", ptw_resp_ready_o);
//     $display("  paddr_o = 0x%08h", paddr_o);
//     $display("  hit_o = %b", hit_o);
//     $display("  fault_o = %b", fault_o);
// end
// endtask

// // 逐步测试
// initial begin
//     clk = 1'b0;
    
//     $display("========================================");
//     $display("TLB Deep Debug Test");
//     $display("========================================");
    
//     // 初始化所有信号
//     rst = 1'b1;
//     req_valid_i = 1'b0;
//     resp_ready_i = 1'b0;
//     ptw_req_ready_i = 1'b0;
//     ptw_resp_valid_i = 1'b0;
//     ptw_pte_i = 32'd0;
//     vaddr_i = 32'd0;
//     access_type_i = 1'b0;
    
//     wait_and_check_signals("Initial state");
//     wait_and_check_signals("After 1 cycle");
    
//     // 复位
//     $display("\n=== RESET SEQUENCE ===");
//     rst = 1'b0;
//     wait_and_check_signals("After reset deassertion");
    
//     // 检查就绪状态
//     if (!req_ready_o) begin
//         $display("[ERROR] TLB not ready after reset!");
//         $finish;
//     end
    
//     // 发送请求
//     $display("\n=== SENDING REQUEST ===");
//     vaddr_i = 32'h12345678;
//     access_type_i = 1'b0;
//     req_valid_i = 1'b1;
//     wait_and_check_signals("Request sent");
    
//     // 检查是否接受请求
//     if (req_ready_o && req_valid_i) begin
//         $display("[SUCCESS] Request accepted");
//     end else begin
//         $display("[ERROR] Request not accepted");
//     end
    
//     // 取消请求信号
//     req_valid_i = 1'b0;
//     wait_and_check_signals("Request signal deasserted");
    
//     // 等待PTW请求
//     $display("\n=== WAITING FOR PTW REQUEST ===");
//     while (!ptw_req_valid_o) begin
//         wait_and_check_signals("Waiting for PTW request");
//         if ($time > 1000) begin
//             $display("[ERROR] Timeout waiting for PTW request");
//             $finish;
//         end
//     end
    
//     $display("[SUCCESS] PTW request generated");
//     $display("  PTW vaddr = 0x%08h (expected: 0x12345678)", ptw_vaddr_o);
    
//     if (ptw_vaddr_o !== 32'h12345678) begin
//         $display("[ERROR] PTW vaddr mismatch!");
//     end
    
//     // 响应PTW请求
//     $display("\n=== RESPONDING TO PTW ===");
//     ptw_req_ready_i = 1'b1;
//     wait_and_check_signals("PTW ready asserted");
//     ptw_req_ready_i = 1'b0;
//     wait_and_check_signals("PTW ready deasserted");
    
//     // 等待TLB准备接收PTW响应
//     while (!ptw_resp_ready_o) begin
//         wait_and_check_signals("Waiting for PTW response ready");
//         if ($time > 1000) begin
//             $display("[ERROR] Timeout waiting for PTW response ready");
//             $finish;
//         end
//     end
    
//     // 发送PTW响应
//     ptw_pte_i = {20'hABCDE, 10'd0, 2'b11};
//     ptw_resp_valid_i = 1'b1;
//     wait_and_check_signals("PTW response sent");
//     ptw_resp_valid_i = 1'b0;
//     wait_and_check_signals("PTW response deasserted");
    
//     // 等待TLB响应
//     $display("\n=== WAITING FOR TLB RESPONSE ===");
//     while (!resp_valid_o) begin
//         wait_and_check_signals("Waiting for TLB response");
//         if ($time > 1000) begin
//             $display("[ERROR] Timeout waiting for TLB response");
//             $finish;
//         end
//     end
    
//     $display("[SUCCESS] TLB response generated");
//     $display("  paddr = 0x%08h (expected: 0xabcde678)", paddr_o);
//     $display("  hit   = %b (expected: 0)", hit_o);
//     $display("  fault = %b (expected: 0)", fault_o);
    
//     // 接收响应
//     resp_ready_i = 1'b1;
//     wait_and_check_signals("Response accepted");
//     resp_ready_i = 1'b0;
//     wait_and_check_signals("Response ready deasserted");
    
//     // 验证结果
//     if (paddr_o == 32'hABCDE678 && hit_o == 1'b0 && fault_o == 1'b0) begin
//         $display("\n[SUCCESS] First request completed correctly!");
//     end else begin
//         $display("\n[ERROR] First request failed!");
//         $display("  Expected: paddr=0xabcde678, hit=0, fault=0");
//         $display("  Got:      paddr=0x%08h, hit=%b, fault=%b", paddr_o, hit_o, fault_o);
//     end
    
//     #100;
//     $display("\n========================================");
//     $display("Deep Debug Test Completed");
//     $display("========================================");
//     $finish;
// end

// // 超时保护
// initial begin
//     #5000;
//     $display("[ERROR] Test timeout!");
//     $finish;
// end

// // VCD dump
// initial begin
//     $dumpfile("tlb_deep_debug.vcd");
//     $dumpvars(0, test_tlb_deep_debug);
// end

// endmodule


// // test_tlb_debug.v
// // TLB调试测试 - 带详细日志

// //`timescale 1ns/1ps
// `include "tlb_params.vh"

// module test_tlb_debug;

// // Clock and reset
// reg clk;
// reg rst;

// // Processor Interface
// reg req_valid_i;
// wire req_ready_o;
// reg [31:0] vaddr_i;
// reg access_type_i;

// wire resp_valid_o;
// reg resp_ready_i;
// wire [31:0] paddr_o;
// wire hit_o;
// wire fault_o;

// // PTW Interface
// wire ptw_req_valid_o;
// reg ptw_req_ready_i;
// wire [31:0] ptw_vaddr_o;

// reg ptw_resp_valid_i;
// wire ptw_resp_ready_o;
// reg [31:0] ptw_pte_i;

// // Test variables
// integer test_passed;
// integer test_failed;
// reg [31:0] task_paddr_result;
// reg task_hit_result;
// reg task_fault_result;

// // DUT instantiation
// tlb dut (
//     .clk(clk),
//     .rst(rst),
//     .req_valid_i(req_valid_i),
//     .req_ready_o(req_ready_o),
//     .vaddr_i(vaddr_i),
//     .access_type_i(access_type_i),
//     .resp_valid_o(resp_valid_o),
//     .resp_ready_i(resp_ready_i),
//     .paddr_o(paddr_o),
//     .hit_o(hit_o),
//     .fault_o(fault_o),
//     .ptw_req_valid_o(ptw_req_valid_o),
//     .ptw_req_ready_i(ptw_req_ready_i),
//     .ptw_vaddr_o(ptw_vaddr_o),
//     .ptw_resp_valid_i(ptw_resp_valid_i),
//     .ptw_resp_ready_o(ptw_resp_ready_o),
//     .ptw_pte_i(ptw_pte_i)
// );

// // Clock generation
// always #5 clk = ~clk;

// // Debug monitoring
// always @(posedge clk) begin
//     if (req_valid_i && req_ready_o) begin
//         $display("[DEBUG] TLB Request:");
//         $display("  vaddr_i = 0x%08h", vaddr_i);
//         $display("  VPN     = 0x%05h (bits[31:12])", vaddr_i[31:12]);
//         $display("  offset  = 0x%03h (bits[11:0])", vaddr_i[11:0]);
//         $display("  access  = %b", access_type_i);
//     end
    
//     if (ptw_req_valid_o && ptw_req_ready_i) begin
//         $display("[DEBUG] PTW Request:");
//         $display("  ptw_vaddr_o = 0x%08h", ptw_vaddr_o);
//     end
    
//     if (ptw_resp_valid_i && ptw_resp_ready_o) begin
//         $display("[DEBUG] PTW Response:");
//         $display("  ptw_pte_i = 0x%08h", ptw_pte_i);
//         $display("  PPN       = 0x%05h (bits[31:12])", ptw_pte_i[31:12]);
//         $display("  flags     = 0x%03h (bits[11:0])", ptw_pte_i[11:0]);
//         $display("  perms     = 0b%02b (bits[1:0])", ptw_pte_i[1:0]);
//     end
    
//     if (resp_valid_o && resp_ready_i) begin
//         $display("[DEBUG] TLB Response:");
//         $display("  paddr_o = 0x%08h", paddr_o);
//         $display("  PPN     = 0x%05h (bits[31:12])", paddr_o[31:12]);
//         $display("  offset  = 0x%03h (bits[11:0])", paddr_o[11:0]);
//         $display("  hit_o   = %b", hit_o);
//         $display("  fault_o = %b", fault_o);
//         $display("  ----");
//     end
// end

// // Tasks
// task reset_dut;
// begin
//     rst = 1'b1;
//     req_valid_i = 1'b0;
//     resp_ready_i = 1'b0;
//     ptw_req_ready_i = 1'b0;
//     ptw_resp_valid_i = 1'b0;
//     ptw_pte_i = 32'd0;
//     @(posedge clk);
//     @(posedge clk);
//     rst = 1'b0;
//     @(posedge clk);
//     $display("[DEBUG] Reset completed");
// end
// endtask

// task automatic ptw_response(input [31:0] pte_value);
// begin
//     $display("[DEBUG] Waiting for PTW request...");
//     wait(ptw_req_valid_o);
//     $display("[DEBUG] PTW request detected, responding with PTE=0x%08h", pte_value);
//     @(posedge clk);
//     ptw_req_ready_i = 1'b1;
//     @(posedge clk);
//     ptw_req_ready_i = 1'b0;
    
//     wait(ptw_resp_ready_o);
//     $display("[DEBUG] TLB ready for PTW response");
//     @(posedge clk);
//     ptw_resp_valid_i = 1'b1;
//     ptw_pte_i = pte_value;
//     @(posedge clk);
//     ptw_resp_valid_i = 1'b0;
//     $display("[DEBUG] PTW response sent");
// end
// endtask

// task tlb_request(
//     input [31:0] vaddr,
//     input access_type,
//     output [31:0] paddr_result,
//     output hit_result,
//     output fault_result
// );
// begin
//     $display("[DEBUG] Sending TLB request: vaddr=0x%08h, type=%b", vaddr, access_type);
//     wait(req_ready_o);
//     @(posedge clk);
//     req_valid_i = 1'b1;
//     vaddr_i = vaddr;
//     access_type_i = access_type;
//     @(posedge clk);
//     req_valid_i = 1'b0;
    
//     $display("[DEBUG] Waiting for TLB response...");
//     wait(resp_valid_o);
//     paddr_result = paddr_o;
//     hit_result = hit_o;
//     fault_result = fault_o;
//     resp_ready_i = 1'b1;
//     @(posedge clk);
//     resp_ready_i = 1'b0;
//     @(posedge clk);
//     $display("[DEBUG] TLB request completed");
// end
// endtask

// task verify_result(
//     input [31:0] got_paddr,
//     input got_hit,
//     input got_fault,
//     input [31:0] exp_paddr,
//     input exp_hit,
//     input exp_fault,
//     input [255:0] test_name
// );
// begin
//     $display("\n[VERIFY] %s", test_name);
//     $display("  Expected: paddr=0x%08h, hit=%b, fault=%b", exp_paddr, exp_hit, exp_fault);
//     $display("  Got:      paddr=0x%08h, hit=%b, fault=%b", got_paddr, got_hit, got_fault);
    
//     if (got_hit !== exp_hit || got_fault !== exp_fault || 
//         (!got_fault && got_paddr !== exp_paddr)) begin
//         $display("  RESULT: FAIL");
//         test_failed = test_failed + 1;
//     end else begin
//         $display("  RESULT: PASS");
//         test_passed = test_passed + 1;
//     end
// end
// endtask

// // Simple focused test
// initial begin
//     clk = 1'b0;
//     test_passed = 0;
//     test_failed = 0;
    
//     $display("========================================");
//     $display("TLB Debug Test Starting");
//     $display("========================================");
    
//     // Reset
//     $display("\n=== Reset Test ===");
//     reset_dut();
    
//     // Simple test case
//     $display("\n=== Simple Test Case ===");
//     $display("Testing: vaddr=0x12345678 -> expect paddr=0xABCDE678");
    
//     fork
//         begin
//             tlb_request(32'h12345678, 1'b0, task_paddr_result, task_hit_result, task_fault_result);
//         end
//         begin
//             // PTE: PPN=0xABCDE, flags=0x3 (Read+Write)
//             ptw_response({20'hABCDE, 10'd0, 2'b11});
//         end
//     join
    
//     verify_result(task_paddr_result, task_hit_result, task_fault_result, 
//                  32'hABCDE678, 1'b0, 1'b0, "Simple miss and update");
    
//     // Test hit on same page
//     $display("\n=== Hit Test on Same Page ===");
//     $display("Testing: vaddr=0x12345ABC -> expect paddr=0xABCDEABC (hit)");
    
//     tlb_request(32'h12345ABC, 1'b0, task_paddr_result, task_hit_result, task_fault_result);
//     verify_result(task_paddr_result, task_hit_result, task_fault_result, 
//                  32'hABCDEABC, 1'b1, 1'b0, "Hit on cached entry");
    
//     // Final summary
//     #100;
//     $display("\n========================================");
//     $display("Test Summary:");
//     $display("  Tests Passed: %d", test_passed);
//     $display("  Tests Failed: %d", test_failed);
//     $display("========================================");
    
//     $finish;
// end

// // Timeout
// initial begin
//     #10000;
//     $display("ERROR: Test timeout!");
//     $finish;
// end

// // VCD dump
// initial begin
//     $dumpfile("tlb_debug.vcd");
//     $dumpvars(0, test_tlb_debug);
// end

// endmodule



// test_integration_tlb.v

//`timescale 1ns/1ps
`include "tlb_params.vh"

module test_integration_tlb;

// Clock and reset
reg clk;
reg rst;

// Processor Interface
reg req_valid_i;
wire req_ready_o;
reg [31:0] vaddr_i;
reg access_type_i;

wire resp_valid_o;
reg resp_ready_i;
wire [31:0] paddr_o;
wire hit_o;
wire fault_o;

// PTW Interface
wire ptw_req_valid_o;
reg ptw_req_ready_i;
wire [31:0] ptw_vaddr_o;

reg ptw_resp_valid_i;
wire ptw_resp_ready_o;
reg [31:0] ptw_pte_i;

// Test variables
integer test_passed;
integer test_failed;
integer i, j;
reg [31:0] test_vaddr;
reg [31:0] test_paddr;
reg [31:0] expected_paddr;

// Task result variables
reg [31:0] task_paddr_result;
reg task_hit_result;
reg task_fault_result;

// Performance counters
integer hit_count;
integer miss_count;
integer fault_count;
integer total_requests;

// DUT instantiation
tlb dut (
    .clk(clk),
    .rst(rst),
    // Processor Interface
    .req_valid_i(req_valid_i),
    .req_ready_o(req_ready_o),
    .vaddr_i(vaddr_i),
    .access_type_i(access_type_i),
    .resp_valid_o(resp_valid_o),
    .resp_ready_i(resp_ready_i),
    .paddr_o(paddr_o),
    .hit_o(hit_o),
    .fault_o(fault_o),
    // PTW Interface
    .ptw_req_valid_o(ptw_req_valid_o),
    .ptw_req_ready_i(ptw_req_ready_i),
    .ptw_vaddr_o(ptw_vaddr_o),
    .ptw_resp_valid_i(ptw_resp_valid_i),
    .ptw_resp_ready_o(ptw_resp_ready_o),
    .ptw_pte_i(ptw_pte_i)
);

// Clock generation
always #5 clk = ~clk;

// Tasks
task reset_dut;
begin
    rst = 1'b1;
    req_valid_i = 1'b0;
    resp_ready_i = 1'b0;
    ptw_req_ready_i = 1'b0;
    ptw_resp_valid_i = 1'b0;
    ptw_pte_i = 32'd0;
    @(posedge clk);
    @(posedge clk);
    rst = 1'b0;
    @(posedge clk);
end
endtask

// Simulate PTW response
task automatic ptw_response(
    input [31:0] pte_value
);
begin
    // Wait for PTW request
    wait(ptw_req_valid_o);
    @(posedge clk);
    ptw_req_ready_i = 1'b1;
    @(posedge clk);
    @(posedge clk);
    ptw_req_ready_i = 1'b0;
    
    // Send PTW response
    wait(ptw_resp_ready_o);
    @(posedge clk);
    ptw_resp_valid_i = 1'b1;
    ptw_pte_i = pte_value;
    @(posedge clk);
    @(posedge clk);
    ptw_resp_valid_i = 1'b0;
end
endtask

// Send TLB request
task tlb_request(
    input [31:0] vaddr,
    input access_type,
    output [31:0] paddr_result,
    output hit_result,
    output fault_result
);
begin
    // Send request
    wait(req_ready_o);
    @(posedge clk);
    req_valid_i = 1'b1;
    vaddr_i = vaddr;
    access_type_i = access_type;
    @(posedge clk);
    @(posedge clk);
    req_valid_i = 1'b0;
    
    // Wait for response
    wait(resp_valid_o);
    paddr_result = paddr_o;
    hit_result = hit_o;
    fault_result = fault_o;
    resp_ready_i = 1'b1;
    @(posedge clk);
    @(posedge clk);
    resp_ready_i = 1'b0;
    @(posedge clk);
end
endtask

// Combined request with PTW handling
task tlb_request_with_ptw(
    input [31:0] vaddr,
    input access_type,
    input [31:0] pte,
    output [31:0] paddr_result,
    output hit_result,
    output fault_result
);
begin
    fork
        begin
            tlb_request(vaddr, access_type, paddr_result, hit_result, fault_result);
        end
        begin
            if (!hit_result) begin
                ptw_response(pte);
            end
        end
    join
end
endtask

// Verify result
task verify_result(
    input [31:0] got_paddr,
    input got_hit,
    input got_fault,
    input [31:0] exp_paddr,
    input exp_hit,
    input exp_fault,
    input [255:0] test_name
);
begin
    if (got_hit !== exp_hit || got_fault !== exp_fault || 
        (!got_fault && got_paddr !== exp_paddr)) begin
        $display("ERROR [%s]:", test_name);
        $display("  Expected: paddr=%h, hit=%b, fault=%b", exp_paddr, exp_hit, exp_fault);
        $display("  Got:      paddr=%h, hit=%b, fault=%b", got_paddr, got_hit, got_fault);
        test_failed = test_failed + 1;
    end else begin
        $display("PASS [%s]", test_name);
        test_passed = test_passed + 1;
    end
    
    // Update performance counters
    total_requests = total_requests + 1;
    if (got_hit) hit_count = hit_count + 1;
    else miss_count = miss_count + 1;
    if (got_fault) fault_count = fault_count + 1;
end
endtask

// Main test sequence
initial begin
    // Initialize
    clk = 1'b0;
    test_passed = 0;
    test_failed = 0;
    hit_count = 0;
    miss_count = 0;
    fault_count = 0;
    total_requests = 0;
    
    $display("========================================");
    $display("TLB Integration Test Starting");
    $display("========================================");
    
    // Test 1: Reset and initial state
    $display("\n=== Test 1: Reset and Initial State ===");
    reset_dut();
    if (!req_ready_o) begin
        $display("ERROR: Not ready after reset");
        test_failed = test_failed + 1;
    end else begin
        $display("PASS: Ready after reset");
        test_passed = test_passed + 1;
    end
    
    // Test 2: First miss and update
    $display("\n=== Test 2: First Miss and Update ===");
    fork
        begin
            tlb_request(32'h12345678, 1'b0, task_paddr_result, task_hit_result, task_fault_result);
        end
        begin
            ptw_response({20'hABCDE, 10'd0, 2'b11}); // PPN=ABCDE, perms=RW
        end
    join
    verify_result(task_paddr_result, task_hit_result, task_fault_result, 32'hABCDE678, 1'b0, 1'b0, "First miss and update");
    
    // Test 3: Hit on previously cached entry
    $display("\n=== Test 3: Hit on Cached Entry ===");
    tlb_request(32'h12345999, 1'b0, task_paddr_result, task_hit_result, task_fault_result);
    verify_result(task_paddr_result, task_hit_result, task_fault_result, 32'hABCDE999, 1'b1, 1'b0, "Hit on cached entry");
    
    // Test 4: Different VPN miss
    $display("\n=== Test 4: Different VPN Miss ===");
    fork
        begin
            tlb_request(32'h99999000, 1'b0, task_paddr_result, task_hit_result, task_fault_result);
        end
        begin
            ptw_response({20'h11111, 10'd0, 2'b11});
        end
    join
    verify_result(task_paddr_result, task_hit_result, task_fault_result, 32'h11111000, 1'b0, 1'b0, "Different VPN miss");
    
    // Test 5: Permission fault - write to read-only
    $display("\n=== Test 5: Permission Fault Tests ===");
    fork
        begin
            tlb_request(32'h55555123, 1'b0, task_paddr_result, task_hit_result, task_fault_result);
        end
        begin
            ptw_response({20'h77777, 10'd0, 2'b01}); // Read-only
        end
    join
    verify_result(task_paddr_result, task_hit_result, task_fault_result, 32'h77777123, 1'b0, 1'b0, "Read from read-only page");
    
    // Now try to write to the same page
    tlb_request(32'h55555456, 1'b1, task_paddr_result, task_hit_result, task_fault_result);
    verify_result(task_paddr_result, task_hit_result, task_fault_result, 32'h00000000, 1'b1, 1'b1, "Write to read-only page");
    
    // Test 6: Set associative behavior
    // $display("\n=== Test 6: Set Associative Behavior ===");
    // // Fill all ways in set 3 (addresses with set_index = 3)
    // for (i = 0; i < NUM_WAYS; i = i + 1) begin
    //     test_vaddr = {8'h10 + i, 12'h003, 12'h000}; // Different VPN, same set
    //     fork
    //         begin
    //             tlb_request(test_vaddr, 1'b0, task_paddr_result, task_hit_result, task_fault_result);
    //         end
    //         begin
    //             ptw_response({8'h20 + i, 12'h003, 10'd0, 2'b11});
    //         end
    //     join
    //     $display("  Filled way %d in set 3", i);
    // end
    
    // // Verify all entries are cached
    // for (i = 0; i < NUM_WAYS; i = i + 1) begin
    //     test_vaddr = {8'h10 + i, 12'h003, 12'h111};
    //     expected_paddr = {8'h20 + i, 12'h003, 12'h111};
    //     tlb_request(test_vaddr, 1'b0, task_paddr_result, task_hit_result, task_fault_result);
    //     // 修复：使用$display替代$sformatf
    //     if (i == 0) verify_result(task_paddr_result, task_hit_result, task_fault_result, expected_paddr, 1'b1, 1'b0, "Set 3 way 0 hit");
    //     else if (i == 1) verify_result(task_paddr_result, task_hit_result, task_fault_result, expected_paddr, 1'b1, 1'b0, "Set 3 way 1 hit");
    //     else if (i == 2) verify_result(task_paddr_result, task_hit_result, task_fault_result, expected_paddr, 1'b1, 1'b0, "Set 3 way 2 hit");
    //     else if (i == 3) verify_result(task_paddr_result, task_hit_result, task_fault_result, expected_paddr, 1'b1, 1'b0, "Set 3 way 3 hit");
    //     else verify_result(task_paddr_result, task_hit_result, task_fault_result, expected_paddr, 1'b1, 1'b0, "Set 3 way X hit");
    // end
    
    // Test 7: LRU replacement
    $display("\n=== Test 7: LRU Replacement ===");
    // Add one more entry to trigger replacement
    test_vaddr = 32'h88888003;
    fork
        begin
            tlb_request(test_vaddr, 1'b0, task_paddr_result, task_hit_result, task_fault_result);
        end
        begin
            ptw_response({20'h99999, 10'd0, 2'b11});
        end
    join
    verify_result(task_paddr_result, task_hit_result, task_fault_result, 32'h99999003, 1'b0, 1'b0, "LRU replacement triggered");
    
    // Verify new entry is cached
    tlb_request(32'h88888ABC, 1'b0, task_paddr_result, task_hit_result, task_fault_result);
    verify_result(task_paddr_result, task_hit_result, task_fault_result, 32'h99999ABC, 1'b1, 1'b0, "New entry after LRU replacement");
    
    // Test 8: PTW fault propagation
    $display("\n=== Test 8: PTW Fault Propagation ===");
    fork
        begin
            tlb_request(32'hDEADBEEF, 1'b1, task_paddr_result, task_hit_result, task_fault_result);
        end
        begin
            ptw_response(32'h00000000); // Invalid PTE (no permissions)
        end
    join
    verify_result(task_paddr_result, task_hit_result, task_fault_result, 32'h00000000, 1'b0, 1'b1, "PTW fault propagation");
    
    // // Test 9: Back-to-back requests
    // $display("\n=== Test 9: Back-to-Back Requests ===");
    // for (i = 0; i < 5; i = i + 1) begin
    //     test_vaddr = {20'hFFF00 + i, 12'h123};
    //     fork
    //         begin
    //             tlb_request(test_vaddr, 1'b0, task_paddr_result, task_hit_result, task_fault_result);
    //         end
    //         begin
    //             if (i == 0) ptw_response({20'hEEE00 + i, 10'd0, 2'b11});
    //         end
    //     join
        
    //     if (i == 0) begin
    //         verify_result(task_paddr_result, task_hit_result, task_fault_result, {20'hEEE00, 12'h123}, 1'b0, 1'b0, "Back-to-back first request");
    //     end else begin
    //         // 修复：使用条件语句替代$sformatf
    //         if (i == 1) verify_result(task_paddr_result, task_hit_result, task_fault_result, {20'hEEE00, 12'h123}, 1'b1, 1'b0, "Back-to-back request 1");
    //         else if (i == 2) verify_result(task_paddr_result, task_hit_result, task_fault_result, {20'hEEE00, 12'h123}, 1'b1, 1'b0, "Back-to-back request 2");
    //         else if (i == 3) verify_result(task_paddr_result, task_hit_result, task_fault_result, {20'hEEE00, 12'h123}, 1'b1, 1'b0, "Back-to-back request 3");
    //         else verify_result(task_paddr_result, task_hit_result, task_fault_result, {20'hEEE00, 12'h123}, 1'b1, 1'b0, "Back-to-back request 4");
    //     end
    // end
    
    // Test 10: Stress test - random addresses
    $display("\n=== Test 10: Stress Test ===");
    for (i = 0; i < 20; i = i + 1) begin
        test_vaddr = $random;
        access_type_i = $random & 1'b1;
        
        fork
            begin
                tlb_request(test_vaddr, access_type_i, task_paddr_result, task_hit_result, task_fault_result);
            end
            begin
                // Only respond with PTW if it's a miss
                if (!task_hit_result) begin
                    ptw_pte_i = {test_vaddr[31:12], 10'd0, 2'b11};
                    ptw_response(ptw_pte_i);
                end
            end
        join
        
        $display("  Stress request %d: vaddr=%h, hit=%b", i, test_vaddr, task_hit_result);
    end
    
    // Final report
    #100;
    $display("\n========================================");
    $display("Test Summary:");
    $display("  Tests Passed: %d", test_passed);
    $display("  Tests Failed: %d", test_failed);
    $display("Performance Statistics:");
    $display("  Total Requests: %d", total_requests);
    $display("  Hits: %d (%.1f%%)", hit_count, hit_count * 100.0 / total_requests);
    $display("  Misses: %d (%.1f%%)", miss_count, miss_count * 100.0 / total_requests);
    $display("  Faults: %d (%.1f%%)", fault_count, fault_count * 100.0 / total_requests);
    
    if (test_failed == 0) begin
        $display("ALL TESTS PASSED!");
    end else begin
        $display("SOME TESTS FAILED!");
    end
    $display("========================================");
    
    $finish;
end

// Timeout watchdog
initial begin
    #100000;
    $display("ERROR: Test timeout!");
    $finish;
end

// VCD dump for waveform viewing
initial begin
    $dumpfile("test_integration_tlb.vcd");
    $dumpvars(0, test_integration_tlb);
end

endmodule
