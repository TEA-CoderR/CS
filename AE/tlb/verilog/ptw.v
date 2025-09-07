// module ptw (
//     input clk,
//     input rst,
    
//     // TLB Interface
//     input ptw_req_valid_i,          
//     output reg ptw_req_ready_o,     
//     input [31:0] ptw_vaddr_i,       
//     output reg ptw_resp_valid_o,    
//     input ptw_resp_ready_i,         
//     output reg [31:0] ptw_pte_o,    
    
//     // Memory Interface
//     output reg mem_req_valid_o,     
//     input mem_req_ready_i,          
//     output reg [31:0] mem_addr_o,   
//     input mem_resp_valid_i,         
//     output reg mem_resp_ready_o,    
//     input [31:0] mem_data_i         
// );

// // Page table parameters
// parameter SATP_PPN = 32'h0400; // Page table base address = 0x400

// // State definitions
// parameter ACCEPT_REQ  = 3'd0;
// parameter READ_LEVEL1 = 3'd1;
// parameter WAIT_LEVEL1 = 3'd2;
// parameter READ_LEVEL2 = 3'd3;
// parameter WAIT_LEVEL2 = 3'd4;
// parameter RESPOND     = 3'd5;

// // Internal registers
// reg [2:0] state, next_state;
// reg [31:0] vaddr_reg;
// reg [31:0] level1_pte;

// // Address decomposition
// wire [9:0] vpn1 = vaddr_reg[31:22]; 
// wire [9:0] vpn0 = vaddr_reg[21:12]; 

// // **修复关键问题：地址计算**
// // Level 1 PTE address = base + VPN1*4
// wire [31:0] level1_pte_addr = SATP_PPN + {vpn1, 2'b00};

// // Level 2 PTE address = (L1_PTE[31:10] << 2) + VPN0*4  
// wire [31:0] level2_pte_addr = {level1_pte[31:10], 2'b00} + {vpn0, 2'b00};

// // Next state logic
// always @(*) begin
//     next_state = state;
    
//     case (state)
//         ACCEPT_REQ: begin
//             if (ptw_req_valid_i) begin
//                 next_state = READ_LEVEL1;
//             end
//         end
        
//         READ_LEVEL1: begin
//             if (mem_req_ready_i) begin
//                 next_state = WAIT_LEVEL1;
//             end
//         end
        
//         WAIT_LEVEL1: begin
//             if (mem_resp_valid_i) begin
//                 if (mem_data_i[0] == 1'b0) begin // Invalid
//                     next_state = RESPOND;
//                 end else if (mem_data_i[1] || mem_data_i[3]) begin // Leaf PTE
//                     next_state = RESPOND;
//                 end else begin // Pointer to next level
//                     next_state = READ_LEVEL2;
//                 end
//             end
//         end
        
//         READ_LEVEL2: begin
//             if (mem_req_ready_i) begin
//                 next_state = WAIT_LEVEL2;
//             end
//         end
        
//         WAIT_LEVEL2: begin
//             if (mem_resp_valid_i) begin
//                 next_state = RESPOND;
//             end
//         end
        
//         RESPOND: begin
//             if (ptw_resp_ready_i) begin
//                 next_state = ACCEPT_REQ;
//             end
//         end
        
//         default: begin
//             next_state = ACCEPT_REQ;
//         end
//     endcase
// end

// // Sequential logic
// always @(posedge clk) begin
//     if (rst) begin
//         state <= ACCEPT_REQ;
//         ptw_req_ready_o <= 1'b1;
//         ptw_resp_valid_o <= 1'b0;
//         ptw_pte_o <= 32'h00000000;
//         mem_req_valid_o <= 1'b0;
//         mem_addr_o <= 32'h00000000;
//         mem_resp_ready_o <= 1'b0;
//         vaddr_reg <= 32'h00000000;
//         level1_pte <= 32'h00000000;
//     end else begin
//         state <= next_state;
        
//         case (state)
//             ACCEPT_REQ: begin
//                 if (ptw_req_valid_i) begin
//                     vaddr_reg <= ptw_vaddr_i;
//                     ptw_req_ready_o <= 1'b0;
//                     // **修复：在状态转换后再计算地址**
//                 end else begin
//                     ptw_req_ready_o <= 1'b1;
//                 end
//                 mem_req_valid_o <= 1'b0;
//             end
            
//             READ_LEVEL1: begin
//                 // **修复：使用当前的vaddr_reg计算地址**
//                 mem_addr_o <= SATP_PPN + {vaddr_reg[31:22], 2'b00};
//                 mem_req_valid_o <= 1'b1;
                
//                 if (mem_req_ready_i) begin
//                     mem_req_valid_o <= 1'b0;
//                     mem_resp_ready_o <= 1'b1;
//                 end
//             end
            
//             WAIT_LEVEL1: begin
//                 if (mem_resp_valid_i) begin
//                     level1_pte <= mem_data_i;
//                     mem_resp_ready_o <= 1'b0;
                    
//                     if (mem_data_i[0] == 1'b0) begin // Invalid
//                         ptw_pte_o <= 32'h00000000;
//                         ptw_resp_valid_o <= 1'b1;
//                     end else if (mem_data_i[1] || mem_data_i[3]) begin // Leaf (megapage)
//                         ptw_pte_o <= {mem_data_i[31:20], vaddr_reg[21:12], mem_data_i[9:0]};
//                         ptw_resp_valid_o <= 1'b1;
//                     end
//                     // else: continue to level 2
//                 end
//             end
            
//             READ_LEVEL2: begin
//                 // **修复：使用保存的level1_pte计算L2地址**
//                 mem_addr_o <= {level1_pte[31:10], 2'b00} + {vaddr_reg[21:12], 2'b00};
//                 mem_req_valid_o <= 1'b1;
                
//                 if (mem_req_ready_i) begin
//                     mem_req_valid_o <= 1'b0;
//                     mem_resp_ready_o <= 1'b1;
//                 end
//             end
            
//             WAIT_LEVEL2: begin
//                 if (mem_resp_valid_i) begin
//                     mem_resp_ready_o <= 1'b0;
//                     ptw_pte_o <= mem_data_i; // 直接返回L2 PTE
//                     ptw_resp_valid_o <= 1'b1;
//                 end
//             end
            
//             RESPOND: begin
//                 if (ptw_resp_ready_i) begin
//                     ptw_resp_valid_o <= 1'b0;
//                     ptw_req_ready_o <= 1'b1;
//                 end
//             end
            
//             default: begin
//                 ptw_req_ready_o <= 1'b1;
//                 ptw_resp_valid_o <= 1'b0;
//                 mem_req_valid_o <= 1'b0;
//                 mem_resp_ready_o <= 1'b0;
//             end
//         endcase
//     end
// end

// // Debug monitoring
// always @(posedge clk) begin
//     if (ptw_req_valid_i && ptw_req_ready_o) begin
//         $display("[PTW] Request: vaddr=0x%08h, vpn1=%d, vpn0=%d", ptw_vaddr_i, ptw_vaddr_i[31:22], ptw_vaddr_i[21:12]);
//     end
//     if (mem_req_valid_o && mem_req_ready_i) begin
//         $display("[PTW] Memory Request: addr=0x%08h", mem_addr_o);
//     end
//     if (mem_resp_valid_i && mem_resp_ready_o) begin
//         $display("[PTW] Memory Response: data=0x%08h", mem_data_i);
//     end
//     if (ptw_resp_valid_o && ptw_resp_ready_i) begin
//         $display("[PTW] Response: pte=0x%08h", ptw_pte_o);
//     end
    
//     // **添加状态监控**
//     if (state != next_state) begin
//         $display("[PTW] State change: %d -> %d", state, next_state);
//     end
// end

// endmodule


// ptw.v - 优化的页表遍历器模块
// 修复了状态机逻辑和SystemVerilog语法问题

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
// 调整基地址以适配1024字内存 (0-4095字节 = 0x0000-0x0FFF)
parameter SATP_PPN = 32'h0400; // Page table base address = 0x400 (word index 256)

// State definitions - 使用标准Verilog语法
parameter ACCEPT_REQ  = 3'd0;
parameter READ_LEVEL1 = 3'd1;
parameter WAIT_LEVEL1 = 3'd2;
parameter READ_LEVEL2 = 3'd3;
parameter WAIT_LEVEL2 = 3'd4;
parameter RESPOND     = 3'd5;

// Internal registers
reg [2:0] state, next_state;
reg [31:0] vaddr_reg;
reg [31:0] level1_pte;
reg [31:0] level2_pte;

// Address decomposition
wire [9:0] vpn1 = vaddr_reg[31:22]; // Level 1 VPN
wire [9:0] vpn0 = vaddr_reg[21:12]; // Level 2 VPN

// Level 1 PTE address = base + VPN1*4
wire [31:0] level1_pte_addr = SATP_PPN + {vpn1, 2'b00};
// Level 2 PTE address = (L1_PTE[31:10] << 10) + VPN0*4  
wire [31:0] level2_pte_addr = {level1_pte[31:10], 10'b00} + {vpn0, 2'b00};

// ===================================================================
// Page Table Walker State Machine
// ===================================================================

// Sequential logic
always @(posedge clk) begin
    if (rst) begin
        state <= ACCEPT_REQ;
    end else begin
        state <= next_state;
    end
end

// Next state logic (combinational)
always @(*) begin
    // Default values
    next_state = state;
    
    case (state)
        ACCEPT_REQ: begin
            if (ptw_req_valid_i && ptw_req_ready_o) begin
                next_state = READ_LEVEL1;
            end
        end
        
        READ_LEVEL1: begin
            if (mem_req_ready_i && mem_req_valid_o) begin
                next_state = WAIT_LEVEL1;
            end
        end
        
        WAIT_LEVEL1: begin
            if (mem_resp_valid_i && mem_resp_ready_o) begin
                // Check if Level1 PTE is valid
                if (mem_data_i[0] == 1'b0) begin // Invalid PTE
                    next_state = RESPOND;
                end else begin    
                    next_state = READ_LEVEL2;
                end
            end
        end
        
        READ_LEVEL2: begin
            if (mem_req_ready_i && mem_req_valid_o) begin
                next_state = WAIT_LEVEL2;
            end
        end
        
        WAIT_LEVEL2: begin
            if (mem_resp_valid_i && mem_resp_ready_o) begin
                next_state = RESPOND;
            end
        end
        
        RESPOND: begin
            if (ptw_resp_ready_i && ptw_resp_valid_o) begin
                next_state = ACCEPT_REQ;
            end
        end
        
        default: begin
            next_state = ACCEPT_REQ;
        end
    endcase
end

// Output and control logic
always @(posedge clk) begin
    if (rst) begin
        ptw_req_ready_o  <= 1'b1;
        ptw_resp_valid_o <= 1'b0;
        ptw_pte_o        <= 32'h00000000;
        mem_req_valid_o  <= 1'b0;
        mem_addr_o       <= 32'h00000000;
        mem_resp_ready_o <= 1'b0;
        vaddr_reg        <= 32'h00000000;
        level1_pte       <= 32'h00000000;
        level2_pte       <= 32'h00000000;
    end else begin
        
        case (state)
            ACCEPT_REQ: begin
                //$display("ACCEPT_REQ");
                if (ptw_req_valid_i && ptw_req_ready_o) begin
                    vaddr_reg <= ptw_vaddr_i;
                    // PTW request accepted
                    ptw_req_ready_o <= 1'b0;
                    
                    // // Prepare Level1 memory request
                    // mem_addr_o <= level1_pte_addr;
                    // mem_req_valid_o <= 1'b1;
                end else begin
                    ptw_req_ready_o <= 1'b1;
                    //mem_req_valid_o <= 1'b0;
                end
            end
            
            READ_LEVEL1: begin
                //$display("READ_LEVEL1");
                if (mem_req_ready_i && mem_req_valid_o) begin
                    // Level1 memory request accepted
                    mem_req_valid_o <= 1'b0;
                    // Prepare to receive memory response
                    mem_resp_ready_o <= 1'b1;
                end else begin
                    // Prepare Level1 memory request
                    mem_addr_o <= level1_pte_addr;
                    mem_req_valid_o <= 1'b1;
                end
            end
            
            WAIT_LEVEL1: begin
                //$display("WAIT_LEVEL1");
                if (mem_resp_valid_i && mem_resp_ready_o) begin
                    level1_pte <= mem_data_i;
                    mem_resp_ready_o <= 1'b0;
                    
                    // Check Level1 PTE validity and type
                    if (mem_data_i[0] == 1'b0) begin // Invalid PTE
                        ptw_pte_o <= 32'h00000000; // Return invalid PTE
                        ptw_resp_valid_o <= 1'b1;
                    end /*else begin // Pointer to next level
                        // Prepare Level2 memory request
                        // mem_addr_o <= level2_pte_addr;
                        // mem_req_valid_o <= 1'b1;
                    end*/
                end
            end
            
            READ_LEVEL2: begin
                //$display("READ_LEVEL2");
                if (mem_req_ready_i && mem_req_valid_o) begin
                    // Level2 memory request accepted
                    mem_req_valid_o <= 1'b0;
                    // Prepare to receive memory response
                    mem_resp_ready_o <= 1'b1;
                end else begin
                    // Prepare Level2 memory request
                    mem_addr_o <= level2_pte_addr;
                    mem_req_valid_o <= 1'b1;
                end
            end
            
            WAIT_LEVEL2: begin
                //$display("WAIT_LEVEL2");
                if (mem_resp_valid_i && mem_resp_ready_o) begin
                    level2_pte <= mem_data_i;
                    mem_resp_ready_o <= 1'b0;
                    
                    // Return Level2 PTE (valid or invalid)
                    if (mem_data_i[0] == 1'b0) begin // Invalid PTE
                        ptw_pte_o <= 32'h00000000;
                    end else begin
                        ptw_pte_o <= mem_data_i; // Valid PTE
                    end
                    ptw_resp_valid_o <= 1'b1;
                end
            end
            
            RESPOND: begin
                //$display("RESPOND");
                if (ptw_resp_ready_i && ptw_resp_valid_o) begin
                    // PTW response accepted
                    ptw_resp_valid_o <= 1'b0;
                    // Ready for next request
                    ptw_req_ready_o <= 1'b1;
                end
            end
            
            default: begin
                //$display("default");
                ptw_req_ready_o <= 1'b1;
                ptw_resp_valid_o <= 1'b0;
                mem_req_valid_o <= 1'b0;
                mem_resp_ready_o <= 1'b0;
            end
        endcase
    end
end

// Debug monitoring
always @(posedge clk) begin
    if (ptw_req_valid_i && ptw_req_ready_o) begin
        $display("[PTW] Request: vaddr=0x%08h, vpn1=%d, vpn0=%d", ptw_vaddr_i, ptw_vaddr_i[31:22], ptw_vaddr_i[21:12]);
    end
    if (mem_req_valid_o && mem_req_ready_i) begin
        $display("[PTW] Memory Request: addr=0x%08h", mem_addr_o);
    end
    if (mem_resp_valid_i && mem_resp_ready_o) begin
        $display("[PTW] Memory Response: data=0x%08h", mem_data_i);
    end
    if (ptw_resp_valid_o && ptw_resp_ready_i) begin
        $display("[PTW] Response: pte=0x%08h", ptw_pte_o);
    end
    // if (state != next_state) begin
    //     $display("[PTW] State change: %d -> %d", state, next_state);
    // end
end

endmodule










// // ptw.v - 优化的页表遍历器模块
// // 修复了状态机逻辑和SystemVerilog语法问题

// module ptw (
//     input clk,
//     input rst,
    
//     // TLB Interface
//     /*---------------------Accept request-----------------------------*/
//     input ptw_req_valid_i,          // PTW request valid
//     output reg ptw_req_ready_o,     // PTW request ready
//     input [31:0] ptw_vaddr_i,       // Virtual address from TLB
//     /*----------------------Send response-----------------------------*/
//     output reg ptw_resp_valid_o,    // PTW response valid
//     input ptw_resp_ready_i,         // PTW response ready 
//     output reg [31:0] ptw_pte_o,    // Page table entry
    
//     // Memory Interface
//     /*----------------------Send request------------------------------*/
//     output reg mem_req_valid_o,     // Memory request valid
//     input mem_req_ready_i,          // Memory request ready
//     output reg [31:0] mem_addr_o,   // Memory address
//     /*---------------------Accept response----------------------------*/
//     input mem_resp_valid_i,         // Memory response valid
//     output reg mem_resp_ready_o,    // Memory response ready
//     input [31:0] mem_data_i         // Memory read data
// );

// // Page table parameters
// parameter SATP_PPN = 32'h1000; // Page table base address (word-aligned)

// // State definitions - 使用标准Verilog语法
// parameter ACCEPT_REQ  = 3'd0;
// parameter READ_LEVEL1 = 3'd1;
// parameter WAIT_LEVEL1 = 3'd2;
// parameter READ_LEVEL2 = 3'd3;
// parameter WAIT_LEVEL2 = 3'd4;
// parameter RESPOND     = 3'd5;

// // Internal registers
// reg [2:0] state, next_state;
// reg [31:0] vaddr_reg;
// reg [31:0] level1_pte;
// reg [31:0] level2_pte;

// // Address decomposition
// wire [9:0] vpn1 = vaddr_reg[31:22]; // Level 1 VPN
// wire [9:0] vpn0 = vaddr_reg[21:12]; // Level 2 VPN

// // Level 1 PTE address calculation
// wire [31:0] level1_pte_addr = {SATP_PPN, vpn1, 2'b00};
// // Level 2 PTE address calculation  
// wire [31:0] level2_pte_addr = {level1_pte[31:10], vpn0, 2'b00};

// // ===================================================================
// // Page Table Walker State Machine
// // ===================================================================
// // always @(posedge clk) begin
// //     if (rst) begin
// //         state <= ACCEPT_REQ;
// //         ptw_req_ready_o <= 1'b1;
// //         ptw_resp_valid_o <= 1'b0;
// //         ptw_pte_o <= 32'h00000000;
// //         mem_req_valid_o <= 1'b0;
// //         mem_addr_o <= 32'h00000000;
// //         mem_resp_ready_o <= 1'b0;
// //         vaddr_reg <= 32'h00000000;
// //         level1_pte <= 32'h00000000;
// //         level2_pte <= 32'h00000000;
// //     end else begin
// //         state <= next_state;
// //     end
// // end

// // Next state logic (combinational)
// always @(*) begin
//     // Default values
//     next_state = state;
    
//     case (state)
//         ACCEPT_REQ: begin
//             if (ptw_req_valid_i) begin
//                 next_state = READ_LEVEL1;
//             end
//         end
        
//         READ_LEVEL1: begin
//             if (mem_req_ready_i) begin
//                 next_state = WAIT_LEVEL1;
//             end
//         end
        
//         WAIT_LEVEL1: begin
//             if (mem_resp_valid_i) begin
//                 // Check if Level1 PTE is valid
//                 if (mem_data_i[0] == 1'b0) begin // Invalid PTE
//                     next_state = RESPOND;
//                 end else begin
//                     // Check if it's a leaf PTE (has R or X permissions)
//                     if (mem_data_i[1] || mem_data_i[3]) begin // R or X bit set - leaf PTE
//                         next_state = RESPOND;
//                     end else begin // Pointer to next level
//                         next_state = READ_LEVEL2;
//                     end
//                 end
//             end
//         end
        
//         READ_LEVEL2: begin
//             if (mem_req_ready_i) begin
//                 next_state = WAIT_LEVEL2;
//             end
//         end
        
//         WAIT_LEVEL2: begin
//             if (mem_resp_valid_i) begin
//                 next_state = RESPOND;
//             end
//         end
        
//         RESPOND: begin
//             if (ptw_resp_ready_i) begin
//                 next_state = ACCEPT_REQ;
//             end
//         end
        
//         default: begin
//             next_state = ACCEPT_REQ;
//         end
//     endcase
// end

// // Output and control logic
// always @(posedge clk) begin
//     if (rst) begin
//         state <= ACCEPT_REQ;
//         ptw_req_ready_o <= 1'b1;
//         ptw_resp_valid_o <= 1'b0;
//         ptw_pte_o <= 32'h00000000;
//         mem_req_valid_o <= 1'b0;
//         mem_addr_o <= 32'h00000000;
//         mem_resp_ready_o <= 1'b0;
//         vaddr_reg <= 32'h00000000;
//         level1_pte <= 32'h00000000;
//         level2_pte <= 32'h00000000;
//     end else begin
//         state <= next_state;
        
//         case (state)
//             ACCEPT_REQ: begin
//                 if (ptw_req_valid_i) begin
//                     vaddr_reg <= ptw_vaddr_i;
//                     // PTW request accepted
//                     ptw_req_ready_o <= 1'b0;
                    
//                     // Prepare Level1 memory request
//                     mem_addr_o <= level1_pte_addr;
//                     mem_req_valid_o <= 1'b1;
//                 end else begin
//                     ptw_req_ready_o <= 1'b1;
//                     mem_req_valid_o <= 1'b0;
//                 end
//             end
            
//             READ_LEVEL1: begin
//                 if (mem_req_ready_i) begin
//                     // Level1 memory request accepted
//                     mem_req_valid_o <= 1'b0;
//                     // Prepare to receive memory response
//                     mem_resp_ready_o <= 1'b1;
//                 end
//             end
            
//             WAIT_LEVEL1: begin
//                 if (mem_resp_valid_i) begin
//                     level1_pte <= mem_data_i;
//                     mem_resp_ready_o <= 1'b0;
                    
//                     // Check Level1 PTE validity and type
//                     if (mem_data_i[0] == 1'b0) begin // Invalid PTE
//                         ptw_pte_o <= 32'h00000000; // Return invalid PTE
//                         ptw_resp_valid_o <= 1'b1;
//                     end else if (mem_data_i[1] || mem_data_i[3]) begin // Leaf PTE (R or X set)
//                         // This is a 1GB page (megapage) - construct final PTE
//                         ptw_pte_o <= {mem_data_i[31:20], vpn0, mem_data_i[9:0]};
//                         ptw_resp_valid_o <= 1'b1;
//                     end else begin // Pointer to next level
//                         // Prepare Level2 memory request
//                         mem_addr_o <= level2_pte_addr;
//                         mem_req_valid_o <= 1'b1;
//                     end
//                 end
//             end
            
//             READ_LEVEL2: begin
//                 if (mem_req_ready_i) begin
//                     // Level2 memory request accepted
//                     mem_req_valid_o <= 1'b0;
//                     // Prepare to receive memory response
//                     mem_resp_ready_o <= 1'b1;
//                 end
//             end
            
//             WAIT_LEVEL2: begin
//                 if (mem_resp_valid_i) begin
//                     level2_pte <= mem_data_i;
//                     mem_resp_ready_o <= 1'b0;
                    
//                     // Return Level2 PTE (valid or invalid)
//                     if (mem_data_i[0] == 1'b0) begin // Invalid PTE
//                         ptw_pte_o <= 32'h00000000;
//                     end else begin
//                         ptw_pte_o <= mem_data_i; // Valid PTE
//                     end
//                     ptw_resp_valid_o <= 1'b1;
//                 end
//             end
            
//             RESPOND: begin
//                 if (ptw_resp_ready_i) begin
//                     // PTW response accepted
//                     ptw_resp_valid_o <= 1'b0;
//                     // Ready for next request
//                     ptw_req_ready_o <= 1'b1;
//                 end
//             end
            
//             default: begin
//                 ptw_req_ready_o <= 1'b1;
//                 ptw_resp_valid_o <= 1'b0;
//                 mem_req_valid_o <= 1'b0;
//                 mem_resp_ready_o <= 1'b0;
//             end
//         endcase
//     end
// end

// endmodule