// test_integration_tlb_ptw_memory.v
// TLB + PTW + Memory

`include "tlb_params.vh"

module test_integration_tlb_ptw_memory;

// Clock and reset
reg clk;
reg rst;

// CPU Interface (to TLB)
reg cpu_req_valid;
wire cpu_req_ready;
reg [31:0] cpu_vaddr;
reg cpu_access_type;

wire cpu_resp_valid;
reg cpu_resp_ready;
wire [31:0] cpu_paddr;
wire cpu_hit;
wire cpu_fault;

// TLB-PTW interconnection
wire tlb_ptw_req_valid;
wire tlb_ptw_req_ready;
wire [31:0] tlb_ptw_vaddr;

wire tlb_ptw_resp_valid;
wire tlb_ptw_resp_ready;
wire [31:0] tlb_ptw_pte;

// PTW-Memory interconnection
wire ptw_mem_req_valid;
wire ptw_mem_req_ready;
wire [31:0] ptw_mem_addr;

wire ptw_mem_resp_valid;
wire ptw_mem_resp_ready;
wire [31:0] ptw_mem_data;

// Test variables
integer test_passed;
integer test_failed;
integer hit_count;
integer miss_count;
integer fault_count;
integer total_requests;

reg [31:0] task_paddr_result;
reg task_hit_result;
reg task_fault_result;

// DUT Instantiations
tlb tlb_inst (
    .clk(clk),
    .rst(rst),
    // CPU Interface
    .req_valid_i(cpu_req_valid),
    .req_ready_o(cpu_req_ready),
    .vaddr_i(cpu_vaddr),
    .access_type_i(cpu_access_type),
    .resp_valid_o(cpu_resp_valid),
    .resp_ready_i(cpu_resp_ready),
    .paddr_o(cpu_paddr),
    .hit_o(cpu_hit),
    .fault_o(cpu_fault),
    // PTW Interface
    .ptw_req_valid_o(tlb_ptw_req_valid),
    .ptw_req_ready_i(tlb_ptw_req_ready),
    .ptw_vaddr_o(tlb_ptw_vaddr),
    .ptw_resp_valid_i(tlb_ptw_resp_valid),
    .ptw_resp_ready_o(tlb_ptw_resp_ready),
    .ptw_pte_i(tlb_ptw_pte)
);

ptw ptw_inst (
    .clk(clk),
    .rst(rst),
    // TLB Interface
    .ptw_req_valid_i(tlb_ptw_req_valid),
    .ptw_req_ready_o(tlb_ptw_req_ready),
    .ptw_vaddr_i(tlb_ptw_vaddr),
    .ptw_resp_valid_o(tlb_ptw_resp_valid),
    .ptw_resp_ready_i(tlb_ptw_resp_ready),
    .ptw_pte_o(tlb_ptw_pte),
    // Memory Interface
    .mem_req_valid_o(ptw_mem_req_valid),
    .mem_req_ready_i(ptw_mem_req_ready),
    .mem_addr_o(ptw_mem_addr),
    .mem_resp_valid_i(ptw_mem_resp_valid),
    .mem_resp_ready_o(ptw_mem_resp_ready),
    .mem_data_i(ptw_mem_data)
);

memory memory_inst (
    .clk(clk),
    .rst(rst),
    // PTW Interface
    .mem_req_valid_i(ptw_mem_req_valid),
    .mem_req_ready_o(ptw_mem_req_ready),
    .mem_addr_i(ptw_mem_addr),
    .mem_resp_valid_o(ptw_mem_resp_valid),
    .mem_resp_ready_i(ptw_mem_resp_ready),
    .mem_data_o(ptw_mem_data)
);

// Clock generation
always #5 clk = ~clk;

// Reset task
task reset_system;
begin
    rst = 1'b1;
    cpu_req_valid = 1'b0;
    cpu_resp_ready = 1'b0;
    cpu_vaddr = 32'h00000000;
    cpu_access_type = 1'b0;
    @(posedge clk);
    @(posedge clk);
    rst = 1'b0;
    @(posedge clk);
    $display("[RESET] System reset completed");
end
endtask

// Complete translation task
task complete_translation(
    input [31:0] vaddr,
    input access_type,
    output [31:0] paddr_result,
    output hit_result,
    output fault_result
);
begin
    $display("  [TRANS] Starting translation: vaddr=0x%08h, type=%s", 
             vaddr, access_type ? "WRITE" : "READ");
    
    // 1. Send Request to TLB
    cpu_req_valid = 1'b1;
    cpu_vaddr = vaddr;
    cpu_access_type = access_type;

    // 2. Waiting for the TLB interface to be ready
    do @(posedge clk); while (cpu_req_ready !== 1'b1);
    @(posedge clk);
    // @(posedge clk);
    cpu_req_valid = 1'b0;
    
    // 3. Awaiting Response
    cpu_resp_ready = 1'b1;
    do @(posedge clk); while (cpu_resp_valid !== 1'b1);
    //@(posedge clk);
    paddr_result = cpu_paddr;
    hit_result = cpu_hit;
    fault_result = cpu_fault;
    @(posedge clk);
    cpu_resp_ready = 1'b0;
    @(posedge clk);
    
    $display("  [TRANS] Complete: paddr=0x%08h, hit=%b, fault=%b", 
             paddr_result, hit_result, fault_result);
    
    // Update statistics
    total_requests = total_requests + 1;
    if (hit_result) hit_count = hit_count + 1;
    else miss_count = miss_count + 1;
    if (fault_result) fault_count = fault_count + 1;
end
endtask

// Verify translation result
task verify_translation(
    input [31:0] vaddr,
    input access_type,
    input [31:0] expected_paddr,
    input expected_hit,
    input expected_fault,
    input [511:0] test_name
);
begin
    $display("\n--- Test: %s ---", test_name);
    complete_translation(vaddr, access_type, task_paddr_result, task_hit_result, task_fault_result);
    
    if (task_hit_result == expected_hit && task_fault_result == expected_fault && 
        (task_fault_result == expected_fault && task_paddr_result == expected_paddr)) begin
        $display("PASS [%s]", test_name);
        test_passed = test_passed + 1;
    end else begin
        $display("ERROR [%s]:", test_name);
        $display("  Expected: paddr=0x%08h, hit=%b, fault=%b", expected_paddr, expected_hit, expected_fault);
        $display("  Got:      paddr=0x%08h, hit=%b, fault=%b", task_paddr_result, task_hit_result, task_fault_result);
        test_failed = test_failed + 1;
    end
end
endtask

// Main test sequence
integer i;
reg [31:0] test_vaddr, expected_paddr;
reg [31:0] test_addrs [0:3];
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
    $display("TLB + PTW + Memory Integration Test");
    $display("========================================");
    $display("Memory Layout (from memory.v initialization):");
    $display("  Root PT at 0x0400 (word index 256):");
    $display("    [0] = 0x00000801 -> L2 PT at 0x0800");
    $display("    [1] = 0x12340000 -> Invalid");
    $display("    [2] = 0x00000000 -> Invalid");
    $display("  L2 PT at 0x0800 (word index 512):");
    $display("    [0] = 0x1000000F -> PPN=0x10000, R+W");
    $display("    [1] = 0x1100000F -> PPN=0x11000, R+W");
    $display("    [2] = 0x12000003 -> PPN=0x12000, R-only");
    $display("    [3] = 0x00000000 -> Invalid");
    $display("========================================");
    
    // Test 1: System Reset
    $display("\n=== Test 1: System Reset ===");
    reset_system();
    if (!cpu_req_ready) begin
        $display("ERROR: System not ready after reset");
        test_failed = test_failed + 1;
    end else begin
        $display("PASS: System ready after reset");
        test_passed = test_passed + 1;
    end
    
    // Test 2: First translation (not found in TLB - ptw - hit)
    $display("\n=== Test 2: First Translation (Page Table Walk) ===");
    // VAddr: 0x00000000 -> VPN1=0, VPN0=0
    // Expected: L1[0]=0x00000801 -> L2[0]=0x1000000F -> PPN=0x10000
    verify_translation(32'h00000000, 1'b0, 32'h10000000, 1'b1, 1'b0, "VPN=0x00000 - not found in TLB - ptw - hit");
    
    // Test 3: Found in TLB (same page)
    $display("\n=== Test 3: Found in TLB ===");
    // Same page as previous, should found in TLB
    verify_translation(32'h00000000, 1'b0, 32'h10000000, 1'b1, 1'b0, "VPN=0x00000 - found in TLB - hit");
    
    // Test 4: Second page in same L2 table (not found in TLB - ptw - hit)
    $display("\n=== Test 4: Second Page (Same L2 Table) ===");
    // VAddr: 0x00001000 -> VPN1=0, VPN0=1
    // Expected: L1[0]=0x00000801 -> L2[1]=0x1100000F -> PPN=0x11000
    verify_translation(32'h00001000, 1'b0, 32'h11000000, 1'b1, 1'b0, "VPN=0x00001 - not found in TLB - ptw - hit");
    
    // Test 5: TLB Hit (same page with different offset - found in TLB)
    $display("\n=== Test 5: Found in TLB ===");
    verify_translation(32'h00001ABC, 1'b0, 32'h11000ABC, 1'b1, 1'b0, "VPN=0x00001 - found in TLB - hit");
    
    // Test 6: Third page in same L2 table (not found in TLB - ptw - hit)
    $display("\n=== Test 6: Third Page Translation ===");
    // VAddr: 0x00002000 -> VPN1=0, VPN0=2
    // Expected: L1[0]=0x00000801 -> L2[2]=0x12000003 -> PPN=0x12000
    verify_translation(32'h00002000, 1'b0, 32'h12000000, 1'b1, 1'b0, "VPN=0x00002 - not found in TLB - ptw - hit");
    
    // Test 7: Write access to not-writable page and writable page (Permission check)
    $display("\n=== Test 7: Write Access Tests ===");
    // VAddr: 0x00002456 -> VPN1=0, VPN0=2
    // Expected: L1[0]=0x00000801 -> L2[2]=0x12000003 -> PPN=0x12000
    verify_translation(32'h00002456, 1'b1, 32'h00000000, 1'b1, 1'b1, "Write to R-only page (fault)");    
    
    // VAddr: 0x00000789 -> VPN1=0, VPN0=0
    // Expected: L1[0]=0x00000801 -> L2[0]=0x1000000F -> PPN=0x10000
    verify_translation(32'h00000789, 1'b1, 32'h10000789, 1'b1, 1'b0, "Write to R+W page (hit)");
    
    // Test 8: Invalid page table entry (not found in TLB - ptw - miss)
    $display("\n=== Test 8: Invalid Page Table Entries ===");
    // VAddr: 0x00003000 -> VPN1=0, VPN0=3
    // Expected: L1[0]=0x00000801 -> L2[3]=0x00000000 (invalid)
    verify_translation(32'h00003000, 1'b0, 32'h00000000, 1'b0, 1'b1, "VPN=0x00003 - not found in TLB - ptw - miss");
    
    // VAddr: 0x00400000 -> VPN1=1, VPN0=0
    // Expected: L1[1]=0x12340000 (invalid)
    verify_translation(32'h00400000, 1'b0, 32'h00000000, 1'b0, 1'b1, "VPN=0x00400 - not found in TLB - ptw - miss");

    // VAddr: 0x00800000 -> VPN1=2, VPN0=0
    // Expected: L1[2]=0x00000000 (invalid)
    verify_translation(32'h00800000, 1'b0, 32'h00000000, 1'b0, 1'b1, "VPN=0x00800 - not found in TLB - ptw - miss");
    
    // Test 9: TLB replacement strategy
    $display("\n=== Test 9: TLB replacement strategy ===");    
    // Fill TLB Set 1 with 4 different vpn
    // VAddr: 0x00018000 -> VPN1=0, VPN0=0x18=24
    // Expected: L1[0]=0x00000801 -> L2[24]=0x1234500F -> PPN=0x12345
    verify_translation(32'h00018000, 1'b0, 32'h12345000, 1'b1, 1'b0, "VPN=0x00018 - not found in TLB - ptw - hit");

    // VAddr: 0x00028000 -> VPN1=0, VPN0=0x28=40
    // Expected: L1[0]=0x00000801 -> L2[40]=0x2234500F -> PPN=0x22345
    verify_translation(32'h00028000, 1'b0, 32'h22345000, 1'b1, 1'b0, "VPN=0x00028 - not found in TLB - ptw - hit");

    // VAddr: 0x00038000 -> VPN1=0, VPN0=0x38=56
    // Expected: L1[0]=0x00000801 -> L2[56]=0x3234500F -> PPN=0x32345
    verify_translation(32'h00038000, 1'b0, 32'h32345000, 1'b1, 1'b0, "VPN=0x00038 - not found in TLB - ptw - hit");

    // VAddr: 0x00048000 -> VPN1=0, VPN0=0x48=72
    // Expected: L1[0]=0x00000801 -> L2[72]=0x3234500F -> PPN=0x42345
    verify_translation(32'h00048000, 1'b0, 32'h42345000, 1'b1, 1'b0, "VPN=0x00048 - not found in TLB - ptw - hit");

    // Read three addresses and increment their LRU values
    verify_translation(32'h00018000, 1'b0, 32'h12345000, 1'b1, 1'b0, "VPN=0x00018 - found in TLB - update lru_count");
    verify_translation(32'h00028000, 1'b0, 32'h22345000, 1'b1, 1'b0, "VPN=0x00028 - found in TLB - update lru_count");
    verify_translation(32'h00048000, 1'b0, 32'h42345000, 1'b1, 1'b0, "VPN=0x00048 - found in TLB - update lru_count");

    // Read a new address, The VPN 0x00038 should be replaced
    // VAddr: 0x00058000 -> VPN1=0, VPN0=0x58=88
    // Expected: L1[0]=0x00000801 -> L2[88]=0x5234500F -> PPN=0x52345
    verify_translation(32'h00058000, 1'b0, 32'h52345000, 1'b1, 1'b0, "VPN=0x00058 - not found in TLB - ptw - hit");

    // Verify that the vpn has been correctly replaced (VPN 0x00031)
    verify_translation(32'h00018000, 1'b0, 32'h12345000, 1'b1, 1'b0, "VPN=0x00018 - found in TLB - update lru_count");
    verify_translation(32'h00028000, 1'b0, 32'h22345000, 1'b1, 1'b0, "VPN=0x00028 - found in TLB - update lru_count");
    verify_translation(32'h00038000, 1'b0, 32'h32345000, 1'b1, 1'b0, "VPN=0x00038 - not found in TLB - ptw - hit");
    verify_translation(32'h00048000, 1'b0, 32'h42345000, 1'b1, 1'b0, "VPN=0x00048 - found in TLB - update lru_count");
    
    // Test 10: Comprehensive test
    $display("\n=== Test 10: Comprehensive Integration Test ===");
    
    for (i = 0; i < 20; i = i + 1) begin
        // Generate addresses in valid ranges
        case (i % 4)
            0: test_vaddr = {20'h00000, i[11:0]};  // Maps to 0x10000xxx
            1: test_vaddr = {20'h00001, i[11:0]};  // Maps to 0x11000xxx
            2: test_vaddr = {20'h00002, i[11:0]};  // Maps to 0x12000xxx
            3: test_vaddr = {20'h00003, i[11:0]};  // Maps to 0x00000000 (Invalid page)
        endcase
        
        complete_translation(test_vaddr, 0, task_paddr_result, task_hit_result, task_fault_result);
        
        if (!task_fault_result) begin
            // Verify address translation is consistent
            case (test_vaddr[31:12])
                20'h00000: expected_paddr = {20'h10000, i[11:0]};
                20'h00001: expected_paddr = {20'h11000, i[11:0]};
                20'h00002: expected_paddr = {20'h12000, i[11:0]};
                20'h00003: expected_paddr = 32'h00000000;
                default:   expected_paddr = 32'h00000000;
            endcase
            
            if (task_paddr_result == expected_paddr) begin
                test_passed = test_passed + 1;
            end else begin
                $display("  ERROR: Address translation mismatch for 0x%08h", test_vaddr);
                $display("    Expected: 0x%08h, Got: 0x%08h", expected_paddr, task_paddr_result);
                test_failed = test_failed + 1;
            end
        end
    end
    
    // Final delay and report
    #100;
    $display("\n========================================");
    $display("Integration Test Summary");
    $display("========================================");
    $display("Test Results:");
    $display("  Tests Passed: %d", test_passed);
    $display("  Tests Failed: %d", test_failed);
    $display("  Success Rate: %0.1f%%", (test_passed * 100.0) / (test_passed + test_failed));
    $display("");
    $display("Performance Statistics:");
    $display("  Total Requests: %d", total_requests);
    $display("  TLB Hits: %d (%0.1f%%)", hit_count, (hit_count * 100.0) / total_requests);
    $display("  TLB Misses: %d (%0.1f%%)", miss_count, (miss_count * 100.0) / total_requests);
    $display("  Page Faults: %d (%0.1f%%)", fault_count, (fault_count * 100.0) / total_requests);
    $display("  Hit Rate: %0.1f%%", (hit_count * 100.0) / total_requests);
    $display("========================================");
    
    if (test_failed == 0) begin
        $display("INTEGRATION_TLB_PTW_MEMORY:\t ALL TESTS PASSED!");
        $display("The complete TLB+PTW+Memory integration works correctly!");
    end else begin
        $display("INTEGRATION_TLB_PTW_MEMORY:\t SOME TESTS FAILED!");
        $display("Please check the integration between modules.");
    end
    $display("========================================");
    
    $finish;
end

// Timeout protection
initial begin
    #500000;  // Long timeout for complete integration test
    $display("ERROR: Integration test timeout!");
    $finish;
end

// VCD dump for debugging
initial begin
    $dumpfile("test_integration_tlb_ptw_memory.vcd");
    $dumpvars(0, test_integration_tlb_ptw_memory);
end

// // Monitor pipeline activity
// always @(posedge clk) begin
//     if (tlb_ptw_req_valid && tlb_ptw_req_ready) begin
//         $display("  [PIPELINE] TLB->PTW request: vaddr=0x%08h", tlb_ptw_vaddr);
//     end
//     if (ptw_mem_req_valid && ptw_mem_req_ready) begin
//         $display("  [PIPELINE] PTW->Memory request: addr=0x%08h", ptw_mem_addr);
//     end
//     if (ptw_mem_resp_valid && ptw_mem_resp_ready) begin
//         $display("  [PIPELINE] Memory->PTW response: data=0x%08h", ptw_mem_data);
//     end
//     if (tlb_ptw_resp_valid && tlb_ptw_resp_ready) begin
//         $display("  [PIPELINE] PTW->TLB response: pte=0x%08h", tlb_ptw_pte);
//     end
// end

// // Performance monitoring
// integer cycle_count;
// integer active_translations;
// integer tlb_lookups;
// integer ptw_requests;
// integer memory_accesses;

// always @(posedge clk) begin
//     if (rst) begin
//         cycle_count = 0;
//         active_translations = 0;
//         tlb_lookups = 0;
//         ptw_requests = 0;
//         memory_accesses = 0;
//     end else begin
//         cycle_count = cycle_count + 1;
        
//         if (cpu_req_valid && cpu_req_ready) begin
//             tlb_lookups = tlb_lookups + 1;
//         end
        
//         if (tlb_ptw_req_valid && tlb_ptw_req_ready) begin
//             ptw_requests = ptw_requests + 1;
//         end
        
//         if (ptw_mem_req_valid && ptw_mem_req_ready) begin
//             memory_accesses = memory_accesses + 1;
//         end
        
//         if (cpu_resp_valid && cpu_resp_ready) begin
//             active_translations = active_translations + 1;
//         end
//     end
// end

// // Final performance summary
// always @(posedge clk) begin
//     if (test_passed + test_failed > 50 && cycle_count > 10000) begin
//         $display("\n[PERFORMANCE] Detailed Statistics:");
//         $display("  Total Cycles: %d", cycle_count);
//         $display("  TLB Lookups: %d", tlb_lookups);  
//         $display("  PTW Requests: %d", ptw_requests);
//         $display("  Memory Accesses: %d", memory_accesses);
//         $display("  Completed Translations: %d", active_translations);
        
//         if (active_translations > 0) begin
//             $display("  Average Cycles/Translation: %0.1f", cycle_count * 1.0 / active_translations);
//             $display("  Miss Penalty (PTW Rate): %0.1f%%", (ptw_requests * 100.0) / tlb_lookups);
//         end
//     end
// end

endmodule