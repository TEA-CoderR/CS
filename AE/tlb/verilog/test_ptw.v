// test_ptw.v

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

// Memory simulation
reg [31:0] sim_mem [0:1023];
initial begin
    integer i;
    // Initialize memory
    for (i = 0; i < 1024; i = i + 1) begin
        sim_mem[i] = 32'h00000000;
    end
    
    // Root PT at 0x400 (word_index = 0x400>>2 = 256)
    sim_mem[256 + 0] = 32'h00000801; // VPN1[31:22]=0: L2 PT at 0x800, Valid
    sim_mem[256 + 1] = 32'h12340007; // VPN1[31:22]=1: Megapage PPN=0x1234, V|W|R
    sim_mem[256 + 2] = 32'h00000000; // VPN1[31:22]=2: Invalid entry
    
    // L2 PT at 0x800 (word index = 0x800>>2 = 512)  
    sim_mem[512 + 0] = 32'h1000000F; // VPN0[21:12]=0: PPN=0x10000, V|W|R
    sim_mem[512 + 1] = 32'h1100000F; // VPN0[21:12]=1: PPN=0x11000, V|W|R  
    sim_mem[512 + 2] = 32'h12000007; // VPN0[21:12]=2: PPN=0x12000, V|W|R
    sim_mem[512 + 3] = 32'h00000000; // VPN0[21:12]=3: Invalid entry
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
    
    // 1. Send PTW Request
    ptw_req_valid_i = 1'b1;
    ptw_vaddr_i = vaddr;

    // 2. Waiting for the PTW interface to be ready
    do @(posedge clk); while (ptw_req_ready_o !== 1'b1);
    @(posedge clk);
    ptw_req_valid_i = 1'b0;
    
    // 3. Awaiting Response
    ptw_resp_ready_i = 1'b1;
    do @(posedge clk); while (ptw_resp_valid_o !== 1'b1);
    @(posedge clk);
    pte_result = ptw_pte_o;
    
    // ptw_resp_ready_i = 1'b1;
    // @(posedge clk);
    // @(posedge clk);
    ptw_resp_ready_i = 1'b0;
    @(posedge clk);
    
    $display("  [PTW] Translation complete: pte=0x%08h", pte_result);
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
reg [31:0] test_vaddrs [0:6];
reg [31:0] expected_ptes [0:6];
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
    
    // Test 2: Two-level page table walk
    $display("\n=== Test 2: Two-Level Page Table Walk ===");
    // VAddr: 0x00000000 -> VPN1=0, VPN0=0 -> Should access L1[0] then L2[0]
    verify_translation(32'h00000000, 32'h1000000F, "PTW - VPN1=0,VPN0=0");
    
    // VAddr: 0x00001000 -> VPN1=0, VPN0=1 -> Should access L1[0] then L2[1]  
    verify_translation(32'h00001000, 32'h1100000F, "PTW - VPN1=0,VPN0=1");
    
    // VAddr: 0x00002000 -> VPN1=0, VPN0=2 -> Should access L1[0] then L2[2]
    verify_translation(32'h00002000, 32'h12000007, "PTW - VPN1=0,VPN0=2");
    
    // Test 3: Invalid page table entries
    $display("\n=== Test 3: Invalid Page Table Entries ===");
    //？？？？？？？？ VAddr: 0x80000000 -> VPN1=2, VPN0=0 -> Should access L1[2] (invalid)
    verify_translation(32'h80000000, 32'h00000000, "Invalid L1 entry");
    
    // VAddr: 0x00003000 -> VPN1=0, VPN0=3 -> Should access L1[0] then L2[3] (invalid)
    verify_translation(32'h00003000, 32'h00000000, "Invalid L2 entry");
    
    // Test 4: Comprehensive translation test
    $display("\n=== Test 4: Stress Test ===");
    
    test_vaddrs[0] = 32'h00000000; expected_ptes[0] = 32'h1000000F;  // L2[0]
    test_vaddrs[1] = 32'h00001000; expected_ptes[1] = 32'h1100000F;  // L2[1]  
    test_vaddrs[2] = 32'h00002000; expected_ptes[2] = 32'h12000007;  // L2[2]
    test_vaddrs[3] = 32'h00003000; expected_ptes[3] = 32'h00000000;  // L2[3] invalid
    test_vaddrs[4] = 32'h80000000; expected_ptes[4] = 32'h00000000;  // invalid
    test_vaddrs[5] = 32'hC0000000; expected_ptes[5] = 32'h00000000;  // invalid
    test_vaddrs[6] = 32'h00000800; expected_ptes[6] = 32'h1000000F;  // Same as [0], different offset
    
    for (i = 0; i < 7; i = i + 1) begin
        ptw_translate(test_vaddrs[i], received_pte);
        if (received_pte !== expected_ptes[i]) begin
            $display("ERROR: Stress Test %d failed", i);
            $display("  vaddr=0x%08h, exp=0x%08h, got=0x%08h", 
                     test_vaddrs[i], expected_ptes[i], received_pte);
            test_failed = test_failed + 1;
        end else begin
            $display("PASS: Stress Test %d: 0x%08h -> 0x%08h", 
                     i, test_vaddrs[i], received_pte);
            test_passed = test_passed + 1;
        end
    end
    
    // Final report
    #100;
    $display("\n========================================");
    $display("PTW Test Summary:");
    $display("  Tests Passed: %d", test_passed);
    $display("  Tests Failed: %d", test_failed);
    
    if (test_failed == 0) begin
        $display("PTW:\t\t ALL TESTS PASSED!");
    end else begin
        $display("PTW:\t\t SOME TESTS FAILED!");
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

// VCD dump for debugging
initial begin
    $dumpfile("test_ptw.vcd");
    $dumpvars(0, test_ptw);
end

// Debug monitoring
// always @(posedge clk) begin
//     if (ptw_req_valid_i && ptw_req_ready_o) begin
//         $display("  [DEBUG] PTW request: vaddr=0x%08h, VPN1=%d, VPN0=%d", 
//                  ptw_vaddr_i, ptw_vaddr_i[31:22], ptw_vaddr_i[21:12]);
//     end
//     if (mem_req_valid_o && mem_req_ready_i) begin
//         $display("  [DEBUG] Memory request: addr=0x%08h", mem_addr_o);
//     end
//     if (mem_resp_valid_i && mem_resp_ready_o) begin
//         $display("  [DEBUG] Memory response: data=0x%08h", mem_data_i);
//     end
//     if (ptw_resp_valid_o && ptw_resp_ready_i) begin
//         $display("  [DEBUG] PTW response: pte=0x%08h", ptw_pte_o);
//     end
// end

// always @(posedge clk) begin
//     if (dut.state != dut.next_state) begin
//         $display("[%0t] PTW State: %d -> %d", $time, dut.state, dut.next_state);
//     end
// end

endmodule
