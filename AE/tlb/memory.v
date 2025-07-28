module memory (
    input clk,
    input rst,
    
    // Access Interface
    /*---------------------Accept request-----------------------------*/
    input mem_req_valid_i,          // Memory request valid
    output reg mem_req_ready_o,     // Memory request ready
    input [31:0] mem_addr_i,        // Memory address to be accessed
    /*----------------------Send response-----------------------------*/
    output reg mem_resp_valid_o,    // Memory response valid
    input mem_resp_ready_i,         // Memory response ready
    output reg [31:0] mem_data_o,   // Memory read data
);

// Memory parameters
parameter MEM_SIZE = 1024;
parameter MEM_ADDR_WIDTH = 10; // log2(MEM_SIZE)

// Memory storage
reg [31:0] mem [0:MEM_SIZE-1]; // 1KB memory

// ===================================================================
// Memory Access Logic
// ===================================================================
always @(posedge clk) begin
    if (rst) begin
        mem_resp_valid_o <= 0;
        mem_data_o <= 0;
        
        // Initialize memory with zeros
        for (int i = 0; i < MEM_SIZE; i = i + 1) begin
            mem[i] <= 32'h00000000;
        end
    end else begin
        mem_resp_valid_o <= 0;
        
        if (mem_req_i) begin
            // Check address range
            if (mem_addr_i < (MEM_SIZE << 2)) begin
                mem_data_o <= mem[mem_addr_i[MEM_ADDR_WIDTH+1:2]]; // Word-aligned access
            end else begin
                mem_data_o <= 32'h00000000; // Return 0 for out-of-range accesses
            end
            
            mem_resp_valid_o <= 1'b1;
        end
    end
end

// Add initialization for page table entries
initial begin
    // Initialize root page table at 0x1000
    mem[32'h1000 >> 2] = 32'h2000_0001; // PPN=0x2000, V=1
    mem[32'h2000 >> 2] = 32'h3000_0001; // PPN=0x3000, V=1
end

endmodule