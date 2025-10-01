// test_tlb.v

`include "tlb_params.vh"

module test_integration_tlb;

// Clock and reset
reg clk;
reg rst;

// CPU Interface
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
integer hit_count;
integer miss_count;
integer fault_count;

reg [31:0] task_paddr;
reg task_hit;
reg task_fault;

// Simulated page table
reg [31:0] sim_mem [0:1023];

// DUT instantiation
tlb dut (
    .clk(clk),
    .rst(rst),
    // CPU Interface
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

// Initialize simulated memory
initial begin
    integer i;
    for (i = 0; i < 1024; i = i + 1) begin
        sim_mem[i] = 32'h00000000;
    end
    
    // Root PT at 0x400 (word_index = 256)
    sim_mem[256 + 0] = 32'h00000801; // VPN[31:22]=0: L2 PT at 0x800
    sim_mem[256 + 1] = 32'h12340000; // VPN[31:22]=1: Invalid
    
    // L2 PT at 0x800 (word index = 512)
    sim_mem[512 + 0] = 32'h1000000F; // VPN[21:12]=0: PPN=0x10000, W+R
    sim_mem[512 + 1] = 32'h1100000F; // VPN[21:12]=1: PPN=0x11000, W+R
    sim_mem[512 + 2] = 32'h12000003; // VPN[21:12]=2: PPN=0x12000, R only
    sim_mem[512 + 3] = 32'h00000000; // VPN[21:12]=3: Invalid
    
    // Test entries for replacement
    sim_mem[512 + 24] = 32'h1234500F; // VPN=0x00018
    sim_mem[512 + 40] = 32'h2234500F; // VPN=0x00028
    sim_mem[512 + 56] = 32'h3234500F; // VPN=0x00038
    sim_mem[512 + 72] = 32'h4234500F; // VPN=0x00048
    sim_mem[512 + 88] = 32'h5234500F; // VPN=0x00058
end

// PTW simulation - responds to TLB requests
always @(posedge clk) begin
    if (rst) begin
        ptw_resp_valid_i <= 1'b0;
        ptw_pte_i <= 32'h00000000;
        ptw_req_ready_i <= 1'b1;
    end else begin
        if (ptw_req_valid_o && ptw_req_ready_i) begin
            // Accept PTW request
            ptw_req_ready_i <= 1'b0;
            
            // Simulate page table walk delay
            repeat(6) @(posedge clk);
            
            // Perform simulated page table walk
            begin
                reg [9:0] vpn1, vpn0;
                reg [31:0] l1_pte, l2_pte;
                
                vpn1 = ptw_vaddr_o[31:22];
                vpn0 = ptw_vaddr_o[21:12];
                
                // Read L1 PTE
                l1_pte = sim_mem[256 + vpn1];
                
                if (l1_pte[0] == 1'b0) begin
                    // Invalid L1 entry
                    ptw_pte_i <= 32'h00000000;
                end else begin
                    // Read L2 PTE
                    l2_pte = sim_mem[512 + vpn0];
                    ptw_pte_i <= l2_pte;
                end
            end
            
            // Send response
            ptw_resp_valid_i <= 1'b1;
            do @(posedge clk); while (ptw_resp_ready_o !== 1'b1);
            @(posedge clk);
            ptw_resp_valid_i <= 1'b0;
            ptw_req_ready_i <= 1'b1;
        end
    end
end

// Test tasks
task reset_system;
begin
    rst = 1'b1;
    req_valid_i = 1'b0;
    resp_ready_i = 1'b0;
    vaddr_i = 32'h00000000;
    access_type_i = 1'b0;
    @(posedge clk);
    @(posedge clk);
    rst = 1'b0;
    @(posedge clk);
    $display("[RESET] System reset completed");
end
endtask

task tlb_translate(
    input [31:0] vaddr,
    input access_type,
    output [31:0] paddr_result,
    output hit_result,
    output fault_result
);
begin
    $display("  [TLB] Translating vaddr=0x%08h, type=%s", 
             vaddr, access_type ? "WRITE" : "READ");
    
    // 1. Send request
    req_valid_i = 1'b1;
    vaddr_i = vaddr;
    access_type_i = access_type;
    
    // 2. Wait for ready
    do @(posedge clk); while (req_ready_o !== 1'b1);
    @(posedge clk);
    req_valid_i = 1'b0;
    
    // 3. Wait for response
    resp_ready_i = 1'b1;
    do @(posedge clk); while (resp_valid_o !== 1'b1);
    
    paddr_result = paddr_o;
    hit_result = hit_o;
    fault_result = fault_o;
    
    @(posedge clk);
    resp_ready_i = 1'b0;
    @(posedge clk);
    
    // Update statistics
    if (hit_result) hit_count = hit_count + 1;
    else miss_count = miss_count + 1;
    if (fault_result) fault_count = fault_count + 1;
    
    $display("  [TLB] Result: paddr=0x%08h, hit=%b, fault=%b", 
             paddr_result, hit_result, fault_result);
end
endtask

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
    tlb_translate(vaddr, access_type, task_paddr, task_hit, task_fault);
    
    if (task_paddr == expected_paddr && 
        task_hit == expected_hit && 
        task_fault == expected_fault) begin
        $display("PASS [%s]", test_name);
        test_passed = test_passed + 1;
    end else begin
        $display("ERROR [%s]:", test_name);
        $display("  Expected: paddr=0x%08h, hit=%b, fault=%b", 
                 expected_paddr, expected_hit, expected_fault);
        $display("  Got:      paddr=0x%08h, hit=%b, fault=%b", 
                 task_paddr, task_hit, task_fault);
        test_failed = test_failed + 1;
    end
end
endtask

// Main test sequence
integer i;
initial begin
    // Initialize
    clk = 1'b0;
    test_passed = 0;
    test_failed = 0;
    hit_count = 0;
    miss_count = 0;
    fault_count = 0;
    
    $display("========================================");
    $display("TLB Unit Test Starting");
    $display("========================================");
    
    // Test 1: Reset
    $display("\n=== Test 1: System Reset ===");
    reset_system();
    if (!req_ready_o) begin
        $display("ERROR: TLB not ready after reset");
        test_failed = test_failed + 1;
    end else begin
        $display("PASS: TLB ready after reset");
        test_passed = test_passed + 1;
    end
    
    // Test 2: First translation (TLB miss, PTW hit)
    $display("\n=== Test 2: First translation ===");
    verify_translation(32'h00000000, 1'b0, 32'h10000000, 1'b1, 1'b0, 
                      "VPN=0x00000 - Miss then Hit");
    verify_translation(32'h00001000, 1'b0, 32'h11000000, 1'b1, 1'b0, 
                      "VPN=0x00001 - Miss then Hit");
    verify_translation(32'h00002000, 1'b0, 32'h12000000, 1'b1, 1'b0, 
                      "VPN=0x00002 - Miss then Hit");
    
    // Test 3: TLB hits (same addresses)
    $display("\n=== Test 3: TLB Hit Tests ===");
    verify_translation(32'h00000123, 1'b0, 32'h10000123, 1'b1, 1'b0, 
                      "VPN=0x00000 - TLB Hit");
    verify_translation(32'h00001456, 1'b0, 32'h11000456, 1'b1, 1'b0, 
                      "VPN=0x00001 - TLB Hit");
    verify_translation(32'h00002789, 1'b0, 32'h12000789, 1'b1, 1'b0, 
                      "VPN=0x00002 - TLB Hit");
    
    // Test 4: Permission checks
    $display("\n=== Test 4: Permission Checks ===");
    verify_translation(32'h00000000, 1'b1, 32'h10000000, 1'b1, 1'b0, 
                      "Write to R+W page - Success");
    verify_translation(32'h00001000, 1'b1, 32'h11000000, 1'b1, 1'b0, 
                      "Write to R+W page - Success");
    verify_translation(32'h00002000, 1'b1, 32'h00000000, 1'b1, 1'b1, 
                      "Write to R-only page - Fault");
    
    // Test 5: Invalid page
    $display("\n=== Test 5: Invalid Page Access ===");
    verify_translation(32'h00003000, 1'b0, 32'h00000000, 1'b0, 1'b1, 
                      "VPN=0x00003 - Invalid L2 entry");
    verify_translation(32'h00400000, 1'b0, 32'h00000000, 1'b0, 1'b1, 
                      "VPN=0x00400 - Invalid L1 entry");
    
    // Test 6: TLB replacement
    $display("\n=== Test 6: TLB Replacement (LRU) ===");
    
    // Fill set with 4 entries
    verify_translation(32'h00018000, 1'b0, 32'h12345000, 1'b1, 1'b0, 
                      "Fill way 0: VPN=0x00018");
    verify_translation(32'h00028000, 1'b0, 32'h22345000, 1'b1, 1'b0, 
                      "Fill way 1: VPN=0x00028");
    verify_translation(32'h00038000, 1'b0, 32'h32345000, 1'b1, 1'b0, 
                      "Fill way 2: VPN=0x00038");
    verify_translation(32'h00048000, 1'b0, 32'h42345000, 1'b1, 1'b0, 
                      "Fill way 3: VPN=0x00048");
    
    // Access to update LRU
    verify_translation(32'h00018000, 1'b0, 32'h12345000, 1'b1, 1'b0, 
                      "Access VPN=0x00018 - Update LRU");
    verify_translation(32'h00028000, 1'b0, 32'h22345000, 1'b1, 1'b0, 
                      "Access VPN=0x00028 - Update LRU");
    verify_translation(32'h00048000, 1'b0, 32'h42345000, 1'b1, 1'b0, 
                      "Access VPN=0x00048 - Update LRU");
    
    // New entry should replace VPN=0x00038 (LRU victim)
    verify_translation(32'h00058000, 1'b0, 32'h52345000, 1'b1, 1'b0, 
                      "Replace LRU: VPN=0x00058");
    
    // Verify replacement occurred
    verify_translation(32'h00018000, 1'b0, 32'h12345000, 1'b1, 1'b0, 
                      "VPN=0x00018 still in TLB");
    verify_translation(32'h00028000, 1'b0, 32'h22345000, 1'b1, 1'b0, 
                      "VPN=0x00028 still in TLB");
    verify_translation(32'h00038000, 1'b0, 32'h32345000, 1'b1, 1'b0, 
                      "VPN=0x00038 was replaced (miss)");
    verify_translation(32'h00048000, 1'b0, 32'h42345000, 1'b1, 1'b0, 
                      "VPN=0x00048 still in TLB");
    
    // Test 7: Stress test
    $display("\n=== Test 7: Stress Test ===");
    for (i = 0; i < 10; i = i + 1) begin
        case (i % 3)
            0: tlb_translate({20'h00000, 12'h000 + i}, 1'b0, task_paddr, task_hit, task_fault);
            1: tlb_translate({20'h00001, 12'h000 + i}, 1'b0, task_paddr, task_hit, task_fault);
            2: tlb_translate({20'h00002, 12'h000 + i}, 1'b0, task_paddr, task_hit, task_fault);
        endcase
        
        if (!task_fault) test_passed = test_passed + 1;
        else test_failed = test_failed + 1;
    end
    
    // Final report
    #100;
    $display("\n========================================");
    $display("TLB Test Summary");
    $display("========================================");
    $display("Test Results:");
    $display("  Tests Passed: %d", test_passed);
    $display("  Tests Failed: %d", test_failed);
    $display("  Success Rate: %0.1f%%", (test_passed * 100.0) / (test_passed + test_failed));
    $display("");
    $display("TLB Performance:");
    $display("  Total Accesses: %d", hit_count + miss_count);
    $display("  TLB Hits: %d (%0.1f%%)", hit_count, (hit_count * 100.0) / (hit_count + miss_count));
    $display("  TLB Misses: %d (%0.1f%%)", miss_count, (miss_count * 100.0) / (hit_count + miss_count));
    $display("  Page Faults: %d", fault_count);
    $display("========================================");
    
    if (test_failed == 0) begin
        $display("INTEGRATION_TLB:\t\t ALL TESTS PASSED!");
    end else begin
        $display("INTEGRATION_TLB:\t\t SOME TESTS FAILED!");
    end
    $display("========================================");
    
    $finish;
end

// Timeout
initial begin
    #500000;
    $display("ERROR: Test timeout!");
    $finish;
end

// VCD dump
initial begin
    $dumpfile("test_integration_tlb.vcd");
    $dumpvars(0, test_integration_tlb);
end

endmodule