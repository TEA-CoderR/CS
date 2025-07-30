module test_memory;
    reg clk;
    reg rst;

    reg mem_req_valid_i;
    wire mem_req_ready_o;
    reg [31:0] mem_addr_i;

    wire mem_resp_valid_o;
    reg mem_resp_ready_i;
    wire [31:0] mem_data_o;

    // Instantiate the Unit Test
    memory ut (
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

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test_memory);

        // Initial values
        clk = 0;
        rst = 1;
        mem_req_valid_i = 0;
        mem_addr_i = 0;
        mem_resp_ready_i = 0;

        #20 rst = 0;

        // ==== Test 1: Normal read (valid address) ====
        @(posedge clk);
        mem_req_valid_i = 1;
        mem_addr_i = 32'd400;  // word index = 100 → mem[100] = 0x20000001
        @(posedge clk);
        mem_req_valid_i = 0;

        wait (mem_resp_valid_o);
        mem_resp_ready_i = 1;
        @(posedge clk);
        $display("Test 1: Read from mem[100] = %h (Expected 20000001)", mem_data_o);
        mem_resp_ready_i = 0;

        // === Test 2: Read from mem[200] (should be 0x30000001) ===
        @(posedge clk);
        mem_req_valid_i = 1;
        mem_addr_i = 32'd800;  // 200 * 4 = 800
        @(posedge clk);
        mem_req_valid_i = 0;

        wait (mem_resp_valid_o);
        mem_resp_ready_i = 1;
        @(posedge clk);
        $display("Test 2: Read from mem[200] = %h (Expected: 30000001)", mem_data_o);
        mem_resp_ready_i = 0;

        // === Test 3: Out-of-bounds read (e.g., mem[2000], should return 0) ===
        @(posedge clk);
        mem_req_valid_i = 1;
        mem_addr_i = 32'd8000;  // 2000 * 4 = 8000 > 4KB

        @(posedge clk);
        while (!mem_req_ready_o) @(posedge clk);
        mem_req_valid_i = 0;

        while (!mem_resp_valid_o) @(posedge clk);
        mem_resp_ready_i = 1;
        @(posedge clk);
        $display("Test 3: Read from mem[2000] = %h (Expected: 00000000)", mem_data_o);
        mem_resp_ready_i = 0;

        $display("Memory test finished.");
        #20;
        $finish;
    end

endmodule

