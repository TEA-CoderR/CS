// test_tlb_lookup.v
// TLB查找模块单元测试

//`timescale 1ns/1ps
`include "tlb_params.vh"

module test_tlb_lookup;

// Inputs
reg [31:0] vaddr;
reg access_type;
reg                 tlb_valid     [0:NUM_WAYS-1];
reg [19:0]          tlb_vpn       [0:NUM_WAYS-1];
reg [19:0]          tlb_ppn       [0:NUM_WAYS-1];
reg [1:0]           tlb_perms     [0:NUM_WAYS-1];

// Outputs
wire [19:0] vpn;
wire [SET_INDEX_BITS-1:0] set_index;
wire [11:0] page_offset;
wire hit;
wire [1:0] hit_way;
wire [19:0] hit_ppn;
wire [1:0] hit_perms;
wire perm_fault;

// Test variables
integer test_passed;
integer test_failed;
integer i;

// DUT instantiation
tlb_lookup dut (
    .vaddr(vaddr),
    .access_type(access_type),
    .tlb_valid(tlb_valid),
    .tlb_vpn(tlb_vpn),
    .tlb_ppn(tlb_ppn),
    .tlb_perms(tlb_perms),
    .vpn(vpn),
    .set_index(set_index),
    .page_offset(page_offset),
    .hit(hit),
    .hit_way(hit_way),
    .hit_ppn(hit_ppn),
    .hit_perms(hit_perms),
    .perm_fault(perm_fault)
);

// Test tasks
task init_tlb_invalid;
begin
    for (i = 0; i < NUM_WAYS; i = i + 1) begin
        tlb_valid[i] = 1'b0;
        tlb_vpn[i] = 20'd0;
        tlb_ppn[i] = 20'd0;
        tlb_perms[i] = 2'b00;
    end
end
endtask

task setup_tlb_entry(
    input [1:0] way,
    input valid,
    input [19:0] vpn_val,
    input [19:0] ppn_val,
    input [1:0] perms_val
);
begin
    tlb_valid[way] = valid;
    tlb_vpn[way] = vpn_val;
    tlb_ppn[way] = ppn_val;
    tlb_perms[way] = perms_val;
end
endtask

task check_result(
    input exp_hit,
    input [1:0] exp_way,
    input [19:0] exp_ppn,
    input exp_fault,
    input [127:0] test_name
);
begin
    #1; // Wait for combinational logic
    
    if (hit !== exp_hit) begin
        $display("ERROR [%s]: Hit mismatch. Expected=%b, Got=%b", test_name, exp_hit, hit);
        test_failed = test_failed + 1;
    end else if (exp_hit && !exp_fault) begin
        if (hit_way !== exp_way) begin
            $display("ERROR [%s]: Way mismatch. Expected=%d, Got=%d", test_name, exp_way, hit_way);
            test_failed = test_failed + 1;
        end else if (hit_ppn !== exp_ppn) begin
            $display("ERROR [%s]: PPN mismatch. Expected=%h, Got=%h", test_name, exp_ppn, hit_ppn);
            test_failed = test_failed + 1;
        end else begin
            $display("PASS [%s]", test_name);
            test_passed = test_passed + 1;
        end
    end else if (perm_fault !== exp_fault) begin
        $display("ERROR [%s]: Fault mismatch. Expected=%b, Got=%b", test_name, exp_fault, perm_fault);
        test_failed = test_failed + 1;
    end else begin
        $display("PASS [%s]", test_name);
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
    $display("TLB Lookup Unit Test Starting");
    $display("========================================");
    
    // Test 1: Address field extraction
    $display("\nTest 1: Address field extraction");
    vaddr = 32'hABCDE123;
    #1;
    if (vpn !== 20'hABCDE) begin
        $display("ERROR: VPN extraction failed. Expected=%h, Got=%h", 20'hABCDE, vpn);
        test_failed = test_failed + 1;
    end else if (set_index !== 4'hE) begin
        $display("ERROR: Set index extraction failed. Expected=%h, Got=%h", 4'h1, set_index);
        test_failed = test_failed + 1;
    end else if (page_offset !== 12'h123) begin
        $display("ERROR: Page offset extraction failed. Expected=%h, Got=%h", 12'h123, page_offset);
        test_failed = test_failed + 1;
    end else begin
        $display("PASS: Address field extraction");
        test_passed = test_passed + 1;
    end
    
    // Test 2: TLB miss (all invalid)
    $display("\nTest 2: TLB miss (all invalid)");
    init_tlb_invalid();
    vaddr = 32'h12345678;
    access_type = 1'b0; // Read
    check_result(1'b0, 2'd0, 20'd0, 1'b1, "TLB miss - all invalid");
    
    // Test 3: TLB hit in way 0
    $display("\nTest 3: TLB hit in way 0");
    init_tlb_invalid();
    setup_tlb_entry(2'd0, 1'b1, 20'h12345, 20'h54321, 2'b11);
    vaddr = 32'h12345678;
    access_type = 1'b0; // Read
    check_result(1'b1, 2'd0, 20'h54321, 1'b0, "TLB hit - way 0");
    
    // Test 4: TLB hit in way 3
    $display("\nTest 4: TLB hit in way 3");
    init_tlb_invalid();
    setup_tlb_entry(2'd3, 1'b1, 20'h12345, 20'h99999, 2'b11);
    vaddr = 32'h12345ABC;
    access_type = 1'b0; // Read
    check_result(1'b1, 2'd3, 20'h99999, 1'b0, "TLB hit - way 3");
    
    // Test 5: Multiple valid entries, correct match
    $display("\nTest 5: Multiple valid entries");
    init_tlb_invalid();
    setup_tlb_entry(2'd0, 1'b1, 20'h11111, 20'hAAAAA, 2'b11);
    setup_tlb_entry(2'd1, 1'b1, 20'h22222, 20'hBBBBB, 2'b11);
    setup_tlb_entry(2'd2, 1'b1, 20'h33333, 20'hCCCCC, 2'b11);
    setup_tlb_entry(2'd3, 1'b1, 20'h44444, 20'hDDDDD, 2'b11);
    
    vaddr = 32'h33333FFF;
    access_type = 1'b0;
    check_result(1'b1, 2'd2, 20'hCCCCC, 1'b0, "Multiple entries - match way 2");
    
    // Test 6: Read permission fault
    $display("\nTest 6: Read permission fault");
    init_tlb_invalid();
    setup_tlb_entry(2'd1, 1'b1, 20'h88888, 20'h77777, 2'b00); // No permissions
    vaddr = 32'h88888123;
    access_type = 1'b0; // Read
    check_result(1'b1, 2'd1, 20'h77777, 1'b1, "Read permission fault");
    
    // Test 7: Write permission fault
    $display("\nTest 7: Write permission fault");
    init_tlb_invalid();
    setup_tlb_entry(2'd2, 1'b1, 20'h66666, 20'h55555, 2'b01); // Read only
    vaddr = 32'h66666789;
    access_type = 1'b1; // Write
    check_result(1'b1, 2'd2, 20'h55555, 1'b1, "Write permission fault");
    
    // Test 8: Write permission success
    $display("\nTest 8: Write permission success");
    init_tlb_invalid();
    setup_tlb_entry(2'd0, 1'b1, 20'hFFFFF, 20'hEEEEE, 2'b11); // Read/Write
    vaddr = 32'hFFFFF000;
    access_type = 1'b1; // Write
    check_result(1'b1, 2'd0, 20'hEEEEE, 1'b0, "Write permission success");
    
    // Test 9: VPN mismatch (miss)
    $display("\nTest 9: VPN mismatch");
    init_tlb_invalid();
    setup_tlb_entry(2'd0, 1'b1, 20'h12345, 20'h54321, 2'b11);
    setup_tlb_entry(2'd1, 1'b1, 20'h12346, 20'h64321, 2'b11);
    vaddr = 32'h12347000; // Different VPN
    access_type = 1'b0;
    check_result(1'b0, 2'd0, 20'd0, 1'b1, "VPN mismatch - miss");
    
    // Test 10: Priority encoding (multiple matches shouldn't happen, but test priority)
    $display("\nTest 10: Priority encoding test");
    init_tlb_invalid();
    // In real hardware, this shouldn't happen, but we test the priority encoder
    setup_tlb_entry(2'd0, 1'b1, 20'hABCDE, 20'h11111, 2'b11);
    setup_tlb_entry(2'd1, 1'b1, 20'hABCDE, 20'h22222, 2'b11); // Same VPN (shouldn't happen)
    vaddr = 32'hABCDE567;
    access_type = 1'b0;
    check_result(1'b1, 2'd0, 20'h11111, 1'b0, "Priority encoding - way 0 wins");
    
    // Test 11: Different set indices
    $display("\nTest 11: Different set indices");
    init_tlb_invalid();
    
    // Test with set index 0x5
    setup_tlb_entry(2'd2, 1'b1, 20'h99995, 20'h88885, 2'b11);
    vaddr = 32'h99995123; // Set index = 0x5
    access_type = 1'b0;
    check_result(1'b1, 2'd2, 20'h88885, 1'b0, "Set index 0x5");
    
    // Test with set index 0xF
    vaddr = 32'h9999F123; // Set index = 0xF, different VPN
    check_result(1'b0, 2'd0, 20'd0, 1'b1, "Different set index - miss");
    
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