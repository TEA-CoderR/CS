module test_tlb;
    reg clk;
    reg rst;

    reg req_valid_i;
    wire req_ready_o;
    reg [31:0] vaddr_i;
    reg access_type_i;

    wire resp_valid_o;
    reg resp_ready_i;
    wire [31:0] paddr_o;
    wire hit_o;
    wire fault_o;

    wire ptw_req_valid_o;
    reg ptw_req_ready_i;
    wire [31:0] ptw_vaddr_o;
    reg ptw_resp_valid_i;
    wire ptw_resp_ready_o;
    reg [31:0] ptw_pte_i;

    // Instantiate the TLB
    tlb ut (
        .clk(clk),
        .rst(rst),
        .req_valid_i(req_valid_i),
        .req_ready_o(req_ready_o),
        .vaddr_i(vaddr_i),
        .access_type_i(access_type_i),
        .resp_valid_o(resp_valid_o),
        .resp_ready_i(resp_ready_i),
        .paddr_o(paddr_o),
        .hit_o(hit_o),
        .fault_o(fault_o),
        .ptw_req_valid_o(ptw_req_valid_o),
        .ptw_req_ready_i(ptw_req_ready_i),
        .ptw_vaddr_o(ptw_vaddr_o),
        .ptw_resp_valid_i(ptw_resp_valid_i),
        .ptw_resp_ready_o(ptw_resp_ready_o),
        .ptw_pte_i(ptw_pte_i)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test_tlb);

        $display("Starting TLB test...");
        clk = 0;
        rst = 1;
        req_valid_i = 0;
        vaddr_i = 0;
        access_type_i = 0;
        resp_ready_i = 0;
        ptw_req_ready_i = 0;
        ptw_resp_valid_i = 0;
        ptw_pte_i = 0;

        // Reset phase
        #20;
        rst = 0;

        // Issue a request that causes a TLB miss and triggers PTW
        @(posedge clk);
        req_valid_i = 1;
        vaddr_i = 32'h1234_5678;     // Virtual address
        access_type_i = 0;           // Read access
        //resp_ready_i = 1;

        wait (req_ready_o == 0);     // Wait until TLB accepts

        // Wait for PTW request to become valid
        wait (ptw_req_valid_o == 1);
        @(posedge clk);
        ptw_req_ready_i = 1;

        @(posedge clk);
        ptw_req_ready_i = 0;         // Simulate request accepted

        // PTW responds with valid PTE
        wait (ptw_resp_ready_o == 1);
        @(posedge clk);
        ptw_resp_valid_i = 1;
        ptw_pte_i = {20'hABCDE, 10'b0, 2'b11}; // PPN=ABCDE, read/write permissions

        @(posedge clk);
        ptw_resp_valid_i = 0; // Response consumed

        // Wait until response is valid from TLB
        wait (resp_valid_o == 1);
        @(posedge clk);
        $display("TLB miss handled: PADDR = %h, HIT = %b, FAULT = %b", paddr_o, hit_o, fault_o);

        // Clear request/response
        req_valid_i = 0;
        resp_ready_i = 1;

        @(posedge clk);
        resp_ready_i = 0;

        // Issue same request again, this time should hit
        repeat(2) @(posedge clk);
        req_valid_i = 1;
        vaddr_i = 32'h1234_5678;
        access_type_i = 0;
        resp_ready_i = 1;

        wait (resp_valid_o == 1);
        @(posedge clk);
        $display("TLB hit: PADDR = %h, HIT = %b, FAULT = %b", paddr_o, hit_o, fault_o);

        // Done
        $finish;
    end
endmodule
