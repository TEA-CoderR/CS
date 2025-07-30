module test_ptw;
    reg clk;
    reg rst;

    reg ptw_req_valid_i;
    wire ptw_req_ready_o;
    reg [31:0] ptw_vaddr_i;

    wire ptw_resp_valid_o;
    reg ptw_resp_ready_i;
    wire [31:0] ptw_pte_o;

    wire mem_req_valid_o;
    reg mem_req_ready_i;
    wire [31:0] mem_addr_o;

    reg mem_resp_valid_i;
    wire mem_resp_ready_o;
    reg [31:0] mem_data_i;

    // Instantiate the PYW
    ptw ut (
        .clk(clk),
        .rst(rst),
        .ptw_req_valid_i(ptw_req_valid_i),
        .ptw_req_ready_o(ptw_req_ready_o),
        .ptw_vaddr_i(ptw_vaddr_i),
        .ptw_resp_valid_o(ptw_resp_valid_o),
        .ptw_resp_ready_i(ptw_resp_ready_i),
        .ptw_pte_o(ptw_pte_o),
        .mem_req_valid_o(mem_req_valid_o),
        .mem_req_ready_i(mem_req_ready_i),
        .mem_addr_o(mem_addr_o),
        .mem_resp_valid_i(mem_resp_valid_i),
        .mem_resp_ready_o(mem_resp_ready_o),
        .mem_data_i(mem_data_i)
    );

    // Clock generation
    always #5 clk = ~clk;

    // 4kb memory
    reg [31:0] mem [0:1023];

    // Set page table
    task setup_page_table(input [31:0] va, input [31:0] level1_pte, input [31:0] level2_pte);
        begin
            int lvl1_idx = va[31:22];
            int lvl2_idx = va[21:12];

            mem[{12'h010, lvl1_idx, 2'b00}] = level1_pte;
            mem[{level1_pte[31:10], lvl2_idx, 2'b00}] = level2_pte;
        end
    endtask

    // Memory Interface
    always @(posedge clk) begin
        if (mem_req_valid_o && mem_req_ready_i) begin
            // Memory request accepted
            $display("MEM_REQ: addr = %h", mem_addr_o);
        end

        if (mem_resp_ready_o) begin
            // Provide response
            mem_resp_valid_i <= 1;
            mem_data_i <= mem[mem_addr_o];
        end else begin
            mem_resp_valid_i <= 0;
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test_ptw);

        clk = 0;
        rst = 1;
        ptw_req_valid_i = 0;
        ptw_vaddr_i = 0;
        ptw_resp_ready_i = 0;
        mem_req_ready_i = 1;
        mem_data_i = 0;
        mem_resp_valid_i = 0;

        #20 rst = 0;

        // ==== Test 1: Normal page table translation ====
        // VA = 0xC000_4000 -> vpn1 = 0x300, vpn0 = 0x100
        // SATP_PPN = 0x0010 = 0x1000 shift left 12
        // L1 @ 0x0010_3000, L2 @ 0xDEAD_1000

        setup_page_table(32'hC000_4000, 
                         {22'hDEAD0, 10'b0} | 32'h1,     // L1 PTE: valid
                         {20'hBEEF0, 12'b0} | 32'h3);     // L2 PTE: RW

        @(posedge clk);
        ptw_req_valid_i = 1;
        ptw_vaddr_i = 32'hC000_4000;
        ptw_resp_ready_i = 1;

        @(posedge clk);
        ptw_req_valid_i = 0;

        wait (ptw_resp_valid_o);
        @(posedge clk);
        $display("Test 1 - PTW returned PTE: %h (should be BEEF000)", ptw_pte_o);
        ptw_resp_ready_i = 0;

        // ==== Test 2: L1 PTE invalid ====
        setup_page_table(32'hD000_0000,
                         32'h0, // Invalid L1 PTE
                         32'h0);

        repeat(2) @(posedge clk);
        ptw_req_valid_i = 1;
        ptw_vaddr_i = 32'hD000_0000;
        ptw_resp_ready_i = 1;

        @(posedge clk);
        ptw_req_valid_i = 0;

        wait (ptw_resp_valid_o);
        @(posedge clk);
        $display("Test 2 - Invalid L1 PTE, PTW returned: %h (should be 00000000)", ptw_pte_o);
        ptw_resp_ready_i = 0;

        // ==== Test 3: L2 PTE invalid ====
        setup_page_table(32'hE000_1000,
                         {22'hDEAD1, 10'b0} | 32'h1,     // Valid L1
                         32'h0);                         // Invalid L2

        repeat(2) @(posedge clk);
        ptw_req_valid_i = 1;
        ptw_vaddr_i = 32'hE000_1000;
        ptw_resp_ready_i = 1;

        @(posedge clk);
        ptw_req_valid_i = 0;

        wait (ptw_resp_valid_o);
        @(posedge clk);
        $display("Test 3 - Invalid L2 PTE, PTW returned: %h (should be 00000000)", ptw_pte_o);
        ptw_resp_ready_i = 0;

        $display("All tests done.");
        #20 $finish;
    end

endmodule
