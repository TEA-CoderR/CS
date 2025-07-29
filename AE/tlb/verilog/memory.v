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
    output reg [31:0] mem_data_o   // Memory read data
);

// Memory parameters
parameter MEM_SIZE = 1024;
parameter MEM_ADDR_WIDTH = $clog2(MEM_SIZE); // log2(MEM_SIZE) = 10

// State definitions
// typedef enum logic [1:0] {
//     ACCEPT_REQ,
//     READ_WAIT,
//     RESPOND
// } state_t;
parameter ACCEPT_REQ = 2'b00;
parameter READ_WAIT  = 2'b01;
parameter RESPOND    = 2'b10;

// Memory storage
reg [31:0] mem [0:MEM_SIZE-1]; // 4KB memory

// Internal registers
//state_t state, next_state;
reg [1:0] state;
reg [1:0] next_state;
reg [31:0] mem_addr_reg;

// Convert byte address to word index
wire [MEM_ADDR_WIDTH-1:0] word_index = mem_addr_reg[MEM_ADDR_WIDTH+1:2];

// ===================================================================
// Memory Access State Machine
// ===================================================================
always @(posedge clk) begin
    if (rst) begin
        state <= ACCEPT_REQ;
        mem_req_ready_o <= 1'b1;
        mem_resp_valid_o <= 1'b0;
        mem_data_o <= 32'd0;
        
        // Initialize memory with zeros
        // integer i;
        // for (i = 0; i < MEM_SIZE; i = i + 1) begin
        //     mem[i] <= 32'd0;
        // end
    end else begin
        state <= next_state;
        mem_resp_valid_o <= 1'b0;

        case (state)
            ACCEPT_REQ : begin
                if (mem_req_valid_i) begin
                    mem_addr_reg <= mem_addr_i;
                    // Memory request completed
                    mem_req_ready_o <= 1'b0;

                    next_state <= READ_WAIT;
                end
            end

            READ_WAIT : begin
                // Check address range
                if (word_index < MEM_SIZE) begin
                    mem_data_o <= mem[word_index]; // Word-aligned access
                end else begin
                    mem_data_o <= 32'h00000000; // Return 0 for out-of-range accesses
                end
                // Ready to send memory response
                mem_resp_valid_o <= 1'b1;

                next_state <= RESPOND;
            end

            RESPOND : begin
                if (mem_resp_ready_i) begin
                    // Memory response completed
                    mem_resp_valid_o <= 1'b0;
                    // Ready to receive memory access request in ACCEPT_REQ state
                    mem_req_ready_o <= 1'b1;

                    next_state <= ACCEPT_REQ;
                end
            end
        endcase
    end
end

// Add initialization for page table entries
integer i;
initial begin
    // Initialize memory with zeros
    for (i = 0; i < MEM_SIZE; i = i + 1) begin
        mem[i] <= 32'd0;
    end
    //Initialize root page table at 0x1000
    mem[100] = 32'h2000_0001; // PPN=0x2000, V=1
    mem[200] = 32'h3000_0001; // PPN=0x3000, V=1
end

endmodule