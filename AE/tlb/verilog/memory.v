// memory.v - 优化的内存模块
// 改进了状态机逻辑、地址处理和初始化

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
    output reg [31:0] mem_data_o    // Memory read data
);

// Memory parameters
parameter MEM_SIZE = 1024;                    // Number of 32-bit words
parameter MEM_ADDR_WIDTH = $clog2(MEM_SIZE);  // Address width for word indexing

// State definitions
parameter IDLE        = 2'b00;
parameter READ_ACCESS = 2'b01;
parameter RESPOND     = 2'b10;

// Memory storage - 32-bit word addressable
reg [31:0] mem [0:MEM_SIZE-1];

// Internal registers
reg [1:0] state, next_state;
reg [31:0] mem_addr_reg;

// Address translation: byte address to word index
// Assuming word-aligned accesses (ignore bottom 2 bits)
wire [MEM_ADDR_WIDTH-1:0] word_index = mem_addr_reg[MEM_ADDR_WIDTH+1:2];
wire addr_valid = (mem_addr_reg[31:2] < MEM_SIZE);

// ===================================================================
// Memory Access State Machine
// ===================================================================

// Sequential logic
always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// Next state logic
always @(*) begin
    next_state = state;
    
    case (state)
        IDLE: begin
            if (mem_req_valid_i/* && mem_req_ready_o*/) begin
                next_state = READ_ACCESS;
            end
        end
        
        READ_ACCESS: begin
            next_state = RESPOND;
        end
        
        RESPOND: begin
            if (mem_resp_ready_i/* && mem_resp_valid_o*/) begin
                next_state = IDLE;
            end
        end
        
        default: begin
            next_state = IDLE;
        end
    endcase
end

// Output and control logic
always @(posedge clk) begin
    if (rst) begin
        mem_req_ready_o <= 1'b1;
        mem_resp_valid_o <= 1'b0;
        mem_data_o <= 32'h00000000;
        mem_addr_reg <= 32'h00000000;
    end else begin

        case (state)
            IDLE: begin
                //mem_req_ready_o <= 1'b1;
                if (mem_req_valid_i/* && mem_req_ready_o*/) begin
                    // Accept request
                    mem_addr_reg <= mem_addr_i;
                    mem_req_ready_o <= 1'b0;                  
                end else begin
                    mem_req_ready_o <= 1'b1;
                end
            end
            
            READ_ACCESS: begin
                // Data ready, prepare response
                if (addr_valid) begin
                    mem_data_o <= mem[word_index];
                end else begin
                    mem_data_o <= 32'h00000000; // Out-of-range access
                end
                mem_resp_valid_o <= 1'b1;
            end
            
            RESPOND: begin
                //mem_resp_valid_o <= 1'b1;
                if (mem_resp_ready_i/* && mem_resp_valid_o*/) begin
                    // Response accepted
                    mem_resp_valid_o <= 1'b0;
                    mem_req_ready_o <= 1'b1;
                end
            end
            
            default: begin
                mem_req_ready_o <= 1'b1;
                mem_resp_valid_o <= 1'b0;
            end
        endcase
    end
end

// Memory initialization with page table structure
integer i;
initial begin
    // Initialize all memory to zero
    for (i = 0; i < MEM_SIZE; i = i + 1) begin
        mem[i] = 32'h00000000;
    end
    
    // 根页表结构适配1024字内存
    // PTW期望页表在SATP_PPN地址，我们设为0x400 (word_index=256)
    if (MEM_SIZE >= 256) begin // 确保有足够空间放置页表
        
        // 根页表在物理地址0x400 (word index = 0x400>>2 = 256) 
        mem[256 + 0] = 32'h00000801; // VPN[31:22]=0: 指向L2表@0x800, Valid
        mem[256 + 1] = 32'h12340007; // VPN[31:22]=1: Megapage PPN=0x1234, V|R|W
        mem[256 + 2] = 32'h00000000; // VPN[31:22]=2: Invalid entry (for testing)
        
        if (MEM_SIZE >= 512) begin
            // Level 2 页表在物理地址0x800 (word index = 0x800>>2 = 512)  
            mem[512 + 0] = 32'h1000000F; // VPN[21:12]=0: PPN=0x10000, V|R|W|X
            mem[512 + 1] = 32'h1100000F; // VPN[21:12]=1: PPN=0x11000, V|R|W|X  
            mem[512 + 2] = 32'h12000007; // VPN[21:12]=2: PPN=0x12000, V|R|W
            mem[512 + 3] = 32'h00000000; // VPN[21:12]=3: Invalid entry
        end
        
        $display("Memory initialized with %d words", MEM_SIZE);
        $display("Page table structure (1024-word memory):");
        $display("  Root PT at 0x0400 (word index 256)");
        if (MEM_SIZE >= 512) begin
            $display("  L2 PT at 0x0800 (word index 512)");
        end
        $display("  Usable address range: 0x0000-0x%04X", (MEM_SIZE-1)*4);
        
    end else begin
        $display("Warning: Memory too small for page tables (MEM_SIZE=%d)", MEM_SIZE);
        $display("Need at least 320 words for basic page table structure");
    end
end

// Optional: Add memory monitoring for debugging
always @(posedge clk) begin
    if (mem_req_valid_i && mem_req_ready_o) begin
        $display("[MEM] Request: addr=0x%08h, word_idx=%d", mem_addr_i, mem_addr_i[MEM_ADDR_WIDTH+1:2]);
    end
    if (mem_resp_valid_o && mem_resp_ready_i) begin
        $display("[MEM] Response: data=0x%08h", mem_data_o);
    end
end

endmodule
