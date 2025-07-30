module ptw (
    input clk,
    input rst,
    
    // TLB Interface
    /*---------------------Accept request-----------------------------*/
    input ptw_req_valid_i,          // PTW request valid
    output reg ptw_req_ready_o,     // PTW request ready
    input [31:0] ptw_vaddr_i,       // Virtual address from TLB
    /*----------------------Send response-----------------------------*/
    output reg ptw_resp_valid_o,    // PTW response valid
    input ptw_resp_ready_i,         // PTW response ready 
    output reg [31:0] ptw_pte_o,    // Page table entry
    
    // Memory Interface
    /*----------------------Send request------------------------------*/
    output reg mem_req_valid_o,     // Memory request valid
    input mem_req_ready_i,          // Memory request ready
    output reg [31:0] mem_addr_o,   // Memory address
    /*---------------------Accept response----------------------------*/
    input mem_resp_valid_i,         // Memory response valid
    output reg mem_resp_ready_o,    // Memory response ready
    input [31:0] mem_data_i         // Memory read data
);

// Page table parameters
parameter SATP_PPN = 20'h0010; // Page table base address

// State definitions
typedef enum logic [2:0] {
    ACCEPT_REQ,
    READ_LEVEL1,
    WAIT_LEVEL1,
    READ_LEVEL2,
    WAIT_LEVEL2,
    RESPOND
} state_t;

// Internal registers
state_t state, next_state;
reg [31:0] vaddr_reg;
reg [31:0] level1_pte;
reg [31:0] level2_pte;

// Address decomposition
wire [9:0] vpn1 = vaddr_reg[31:22]; // Level 1 VPN
wire [9:0] vpn0 = vaddr_reg[21:12]; // Level 2 VPN

// ===================================================================
// Page Table Walker State Machine
// ===================================================================
always @(posedge clk) begin
    if (rst) begin
        state <= ACCEPT_REQ;
        ptw_req_ready_o <= 1;
        ptw_resp_valid_o <= 0;
        ptw_pte_o <= 0;
        mem_req_valid_o <= 0;
        mem_addr_o <= 0;
        mem_resp_ready_o <= 0;
        vaddr_reg <= 0;
        level1_pte <= 0;
        level2_pte <= 0;
    end else begin
        state <= next_state;
        
        case (state)
            ACCEPT_REQ: begin               
                if (ptw_req_valid_i) begin
                    vaddr_reg <= ptw_vaddr_i; 
                    // Ptw request completed
                    ptw_req_ready_o <= 0;

                    // Level1 PTE address
                    mem_addr_o <= {SATP_PPN, vpn1, 2'b00};
                    // Send Level1 memory request
                    mem_req_valid_o <= 1;

                    next_state <= READ_LEVEL1;
                end
            end
            
            READ_LEVEL1: begin
                if (mem_req_ready_i) begin
                    // Level1 memory request completed
                    mem_req_valid_o <= 0; 
                    // Ready to receive Level1 memory response in WAIT_LEVEL1 state
                    mem_resp_ready_o <= 1;

                    next_state <= WAIT_LEVEL1;
                end
            end
            
            WAIT_LEVEL1: begin
                if (mem_resp_valid_i) begin
                    level1_pte <= mem_data_i;
                    
                    // Check Level1 PTE validity
                    if (mem_data_i[0] == 0) begin // Invalid PTE
                        ptw_resp_valid_o <= 1;

                        next_state <= RESPOND;
                    end else begin
                        // Send Level2 memory request
                        mem_addr_o <= {mem_data_i[31:12], vpn0, 2'b00}; // Level2 PTE address
                        mem_req_valid_o <= 1;

                        next_state <= READ_LEVEL2;
                    end
                end
            end
            
            READ_LEVEL2: begin
                if (mem_req_ready_i) begin
                    // Level2 memory request completed
                    mem_req_valid_o <= 0;
                    // Ready to receive Level2 memory response in WAIT_LEVEL2 state
                    mem_resp_ready_o <= 1;

                    next_state <= WAIT_LEVEL2;
                end
            end
            
            WAIT_LEVEL2: begin
                if (mem_resp_valid_i) begin
                    level2_pte <= mem_data_i;
                    
                    // Check Level2 PTE validity
                    if (mem_data_i[0] == 0) begin // Invalid PTE
                        // Return 0 on fault
                        ptw_pte_o <= 0;
                    end else begin
                        // Return level2_pte on success
                        ptw_pte_o <= level2_pte; 
                    end
                    // Ready to send ptw response
                    ptw_resp_valid_o <= 1;

                    next_state <= RESPOND;
                end
            end
            
            RESPOND: begin
                if (ptw_resp_ready_i) begin
                    // Ptw response completed
                    ptw_resp_valid_o = 0;
                    // Ready to receive tlb request in ACCEPT_REQ state
                    ptw_req_ready_o <= 1;

                    next_state <= ACCEPT_REQ;
                end
            end
        endcase
    end
end

endmodule