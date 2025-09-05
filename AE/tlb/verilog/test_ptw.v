// test_ptw.v
// PTW (Page Table Walker) 模块单元测试

//`timescale 1ns/1ps

module test_ptw;

// Clock and reset
reg clk;
reg rst;

// TLB Interface
reg ptw_req_valid_i;
wire ptw_req_ready_o;
reg [31:0] ptw_vaddr_i;

wire ptw_resp_valid_o;
reg ptw_resp_ready_i;
wire [31:0] ptw_pte_o;

// Memory Interface (PTW -> Memory)
wire mem_req_valid_o;
reg mem_req_ready_i;
wire [31:0] mem_addr_o;

reg mem_resp_valid_i;
wire mem_resp_ready_o;
reg [31:0] mem_data_i;

// Test variables
integer test_passed;
integer test_failed;
reg [31:0] test_vaddr;
reg [31:0] expected_pte;
reg [31:0] received_pte;

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

// Memory simulation model
reg [31:0] sim_memory [0:1023];

// Initialize simulated memory with page table data
initial begin
    integer i;
    // Clear memory
    for (i = 0; i < 1024; i = i + 1) begin
        sim_memory[i] = 32'h00000000;
    end
    
    // Set up page table structure
    // Root page table at 0x1000 (word index 0x400 = 1024)
    // But we need to adjust for our limited sim_memory size
    
    // Level 1 page table entries (simulate at word index 256)
    sim_memory[256 + 0]     = 32'h00002001; // VPN[31:22]=0x000 -> Level2 at 0x2000, Valid
    sim_memory[256 + 1]     = 32'h00003001; // VPN[31:22]=0x001 -> Level2 at 0x3000, Valid
    // sim_memory[256 + 0x123] = 32'h1230000F; // VPN[31:22]=0x123 -> Megapage PPN=0x12300, V|R|W|X
    // sim_memory[256 + 0x100] = 32'h00000000; // Invalid entry
    
    // Level 2 page table entries (simulate at word index 512 for 0x2000)
    sim_memory[512 + 0]     = 32'h1000000F; // VPN[21:12]=0x000 -> PPN=0x10000, V|R|W|X
    sim_memory[512 + 1]     = 32'h1100000F; // VPN[21:12]=0x001 -> PPN=0x11000, V|R|W|X
    // sim_memory[512 + 0x234] = 32'h23400007; // VPN[21:12]=0x234 -> PPN=0x23400, V|R|W (no X)
    // sim_memory[512 + 0x300] = 32'h00000000; // Invalid entry
    
    // Level 2 page table entries (simulate at word index 768 for 0x3000)  
    sim_memory[768 + 0]     = 32'h2000000F; // VPN[21:12]=0x000 -> PPN=0x20000, V|R|W|X
    sim_memory[768 + 1]     = 32'h2100000F; // VPN[21:12]=0x001 -> PPN=0x21000, V|R|W|X
end

// Memory response model
always @(posedge clk) begin
    if (rst) begin
        mem_req_ready_i <= 1'b1;
        mem_resp_valid_i <= 1'b0;
        mem_data_i <= 32'h00000000;
    end else begin
        // Handle memory request
        if (mem_req_valid_o && mem_req_ready_i) begin
            // Simulate memory access delay
            @(posedge clk);
            // Calculate word index (assuming word-aligned access)
            mem_data_i <= sim_memory[mem_addr_o[11:2]]; // Use lower bits as index
            mem_resp_valid_i <= 1'b1;
            $display("DATA mem_addr_o: data=0x%08h", mem_addr_o[11:2]);
            $display("DATA sim_memory: data=0x%08h", sim_memory[mem_addr_o[11:2]]);
            $display("DATA mem_data_i: data=0x%08h", mem_data_i);
            mem_req_ready_i <= 1'b0;
        end
        
        // Handle memory response
        if (mem_resp_valid_i && mem_resp_ready_o) begin
            mem_resp_valid_i <= 1'b0;
            @(posedge clk);
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
end
endtask

task ptw_request(
    input [31:0] vaddr,
    output [31:0] pte_result
);
begin
    // Send PTW request
    wait(ptw_req_ready_o);
    @(posedge clk);
    ptw_req_valid_i = 1'b1;
    ptw_vaddr_i = vaddr;
    @(posedge clk);
    @(posedge clk);
    ptw_req_valid_i = 1'b0;
    
    // Wait for response
    wait(ptw_resp_valid_o);
    @(posedge clk);
    pte_result = ptw_pte_o;
    $display("Wait for response: addr=0x%08h", ptw_pte_o);
    ptw_resp_ready_i = 1'b1;
    @(posedge clk);
    @(posedge clk);
    ptw_resp_ready_i = 1'b0;
    @(posedge clk);
end
endtask

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
        $display("  VAddr was: 0x%08h", test_vaddr);
        test_failed = test_failed + 1;
    end else begin
        $display("PASS [%s]: PTE=0x%08h", test_name, got_pte);
        test_passed = test_passed + 1;
    end
end
endtask

// Main test sequence
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
    
    // Test 2: Two-level page walk - normal case
    $display("\n=== Test 2: Two-Level Page Walk ===");
    test_vaddr = 32'h00000000; // VPN1=0x000, VPN0=0x000
    expected_pte = 32'h1000000F; // Final PTE from level 2
    ptw_request(test_vaddr, received_pte);
    verify_result(received_pte, expected_pte, "Two-level page walk");
    
    // // Test 3: Two-level page walk - different address
    // $display("\n=== Test 3: Two-Level Page Walk (addr 2) ===");
    // test_vaddr = 32'h00001000; // VPN1=0x000, VPN0=0x001  
    // expected_pte = 32'h1100000F;
    // ptw_request(test_vaddr, received_pte);
    // verify_result(received_pte, expected_pte, "Two-level page walk (addr 2)");
    
    // // Test 4: Different level 1 entry
    // $display("\n=== Test 4: Different Level 1 Entry ===");
    // test_vaddr = 32'h00400000; // VPN1=0x001, VPN0=0x000
    // expected_pte = 32'h2000000F; // From different level 2 table
    // ptw_request(test_vaddr, received_pte);
    // verify_result(received_pte, expected_pte, "Different level 1 entry");
    
    // // Test 6: Invalid level 1 PTE  
    // $display("\n=== Test 6: Invalid Level 1 PTE ===");
    // test_vaddr = 32'h00800000; // VPN1=0x002 (invalid entry)
    // expected_pte = 32'h00000000; // Should return invalid PTE
    // ptw_request(test_vaddr, received_pte);
    // verify_result(received_pte, expected_pte, "Invalid level 1 PTE");
    
    // // Test 7: Invalid level 2 PTE
    // $display("\n=== Test 7: Invalid Level 2 PTE ===");
    // test_vaddr = 32'h00003000; // VPN1=0x000, VPN0=0x003 (invalid L2 entry)
    // expected_pte = 32'h00000000;
    // ptw_request(test_vaddr, received_pte);
    // verify_result(received_pte, expected_pte, "Invalid level 2 PTE");
    
    // // Test 8: Address with different permissions
    // $display("\n=== Test 8: Different Permissions Test ===");
    // test_vaddr = 32'h00002000; // VPN1=0x000, VPN0=0x002
    // expected_pte = 32'h12000007; // Should get PTE with V|R|W (no X)
    // ptw_request(test_vaddr, received_pte);
    // verify_result(received_pte, expected_pte, "Different permissions test");
    
    // // Test 9: Back-to-back requests
    // $display("\n=== Test 9: Back-to-Back Requests ===");
    // test_vaddr = 32'h00000000;
    // expected_pte = 32'h1000000F;
    // ptw_request(test_vaddr, received_pte);
    // verify_result(received_pte, expected_pte, "Back-to-back request 1");
    
    // test_vaddr = 32'h00001000;
    // expected_pte = 32'h1100000F;
    // ptw_request(test_vaddr, received_pte);
    // verify_result(received_pte, expected_pte, "Back-to-back request 2");
    
    // // Test 10: Memory response delay test
    // $display("\n=== Test 10: Memory Response Delay Test ===");
    // // This test verifies PTW can handle slow memory responses
    // test_vaddr = 32'h00001000;
    // expected_pte = 32'h1100000F;
    
    // // Add some delay to memory responses
    // fork
    //     begin
    //         ptw_request(test_vaddr, received_pte);
    //         verify_result(received_pte, expected_pte, "Delayed memory response");
    //     end
    //     begin
    //         // Add artificial delays to memory interface
    //         repeat(3) @(posedge clk);
    //     end
    // join
    
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
    #50000;
    $display("ERROR: PTW test timeout!");
    $finish;
end

endmodule