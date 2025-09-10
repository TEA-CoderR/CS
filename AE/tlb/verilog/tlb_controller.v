// `include "tlb_params.vh"

// module tlb_controller (
//     input clk,
//     input rst,
    
//     // Processor Interface
//     input req_valid_i,
//     input resp_ready_i,
//     output reg req_ready_o,
//     output reg resp_valid_o,
    
//     // PTW Interface
//     input ptw_req_ready_i,
//     input ptw_resp_valid_i,
//     output reg ptw_req_valid_o,
//     output reg ptw_resp_ready_o,
    
//     // Lookup results
//     input hit,
//     input perm_fault,
    
//     // Control signals
//     output reg lookup_en,
//     output reg update_en,
//     output reg lru_update_en,
//     output reg [2:0] state,
//     output reg [2:0] next_state
// );

// // Next state logic (combinational)
// always @(*) begin
//     // Default: stay in current state
//     next_state = state;
    
//     case (state)
//         ACCEPT_REQ: begin
//             if (req_valid_i) begin
//                 next_state = LOOKUP;
//             end
//         end
        
//         LOOKUP: begin
//             if (hit && !perm_fault) begin
//                 next_state = RESPOND;
//             end else if (hit && perm_fault) begin
//                 next_state = RESPOND;
//             end else begin
//                 next_state = PTW_REQ;
//             end
//         end
        
//         PTW_REQ: begin
//             if (ptw_req_ready_i) begin
//                 next_state = PTW_PENDING;
//             end
//         end
        
//         PTW_PENDING: begin
//             if (ptw_resp_valid_i) begin
//                 next_state = UPDATE;
//             end
//         end
        
//         UPDATE: begin
//             next_state = RESPOND;
//         end
        
//         RESPOND: begin
//             if (resp_ready_i) begin
//                 next_state = ACCEPT_REQ;
//             end
//         end
        
//         default: begin
//             next_state = ACCEPT_REQ;
//         end
//     endcase
// end

// // State machine - sequential logic
// always @(posedge clk) begin
//     if (rst) begin
//         state             <= ACCEPT_REQ;
//         req_ready_o       <= 1'b1;
//         resp_valid_o      <= 1'b0;
//         ptw_req_valid_o   <= 1'b0;
//         ptw_resp_ready_o  <= 1'b0;
//         lookup_en         <= 1'b0;
//         update_en         <= 1'b0;
//         lru_update_en     <= 1'b0;
//     end else begin
//         state <= next_state;
        
//         // Update registered outputs based on next state
//         case (next_state)
//             ACCEPT_REQ: begin
//                 req_ready_o       <= 1'b1;
//                 resp_valid_o      <= 1'b0;
//                 ptw_req_valid_o   <= 1'b0;
//                 ptw_resp_ready_o  <= 1'b0;
//                 lookup_en         <= 1'b0;
//                 update_en         <= 1'b0;
//                 lru_update_en     <= 1'b0;
//             end
            
//             LOOKUP: begin
//                 req_ready_o       <= 1'b0;
//                 resp_valid_o      <= 1'b0;
//                 ptw_req_valid_o   <= 1'b0;
//                 ptw_resp_ready_o  <= 1'b0;
//                 lookup_en         <= 1'b1;
//                 update_en         <= 1'b0;
//                 lru_update_en     <= 1'b0;
//             end
            
//             PTW_REQ: begin
//                 req_ready_o       <= 1'b0;
//                 resp_valid_o      <= 1'b0;
//                 ptw_req_valid_o   <= 1'b1;
//                 ptw_resp_ready_o  <= 1'b0;
//                 lookup_en         <= 1'b0;
//                 update_en         <= 1'b0;
//                 lru_update_en     <= 1'b0;
//             end
            
//             PTW_PENDING: begin
//                 req_ready_o       <= 1'b0;
//                 resp_valid_o      <= 1'b0;
//                 ptw_req_valid_o   <= 1'b0;
//                 ptw_resp_ready_o  <= 1'b1;
//                 lookup_en         <= 1'b0;
//                 update_en         <= 1'b0;
//                 lru_update_en     <= 1'b0;
//             end
            
//             UPDATE: begin
//                 req_ready_o       <= 1'b0;
//                 resp_valid_o      <= 1'b0;
//                 ptw_req_valid_o   <= 1'b0;
//                 ptw_resp_ready_o  <= 1'b0;
//                 lookup_en         <= 1'b0;
//                 update_en         <= 1'b1;
//                 lru_update_en     <= 1'b1;  // Also update LRU when installing new entry
//             end
            
//             RESPOND: begin
//                 req_ready_o       <= 1'b0;
//                 resp_valid_o      <= 1'b1;
//                 ptw_req_valid_o   <= 1'b0;
//                 ptw_resp_ready_o  <= 1'b0;
//                 lookup_en         <= 1'b0;
//                 update_en         <= 1'b0;
//                 lru_update_en     <= (state == LOOKUP && hit && !perm_fault) ? 1'b1 : 1'b0;
//             end
            
//             default: begin
//                 req_ready_o       <= 1'b1;
//                 resp_valid_o      <= 1'b0;
//                 ptw_req_valid_o   <= 1'b0;
//                 ptw_resp_ready_o  <= 1'b0;
//                 lookup_en         <= 1'b0;
//                 update_en         <= 1'b0;
//                 lru_update_en     <= 1'b0;
//             end
//         endcase
//     end
// end

// endmodule

// tlb_controller.v

`include "tlb_params.vh"

module tlb_controller (
    input clk,
    input rst,
    
    // Processor Interface
    input req_valid_i,
    input resp_ready_i,
    output reg req_ready_o,
    output reg resp_valid_o,
    
    // PTW Interface
    input ptw_req_ready_i,
    input ptw_resp_valid_i,
    output reg ptw_req_valid_o,
    output reg ptw_resp_ready_o,
    
    // Lookup results
    input hit,
    input perm_fault,
    
    // Control signals
    output reg lookup_en,
    output reg update_en,
    output reg lru_update_en,
    output reg [2:0] state,
    output reg [2:0] next_state
);

// State machine
always @(posedge clk) begin
    if (rst) begin
        state <= ACCEPT_REQ;
    end else begin
        state <= next_state;
    end
end

// Next state logic (combinational)
always @(*) begin
    // Default: stay in current state
    next_state = state;
    
    case (state)
        ACCEPT_REQ: begin
            if (req_valid_i && req_ready_o) begin
                next_state = LOOKUP;
            end
        end
        
        LOOKUP: begin
            if (hit && !perm_fault) begin
                next_state = RESPOND;
            end else if (hit && perm_fault) begin
                next_state = RESPOND;
            end else begin
                next_state = PTW_REQ;
            end
        end
        
        PTW_REQ: begin
            if (ptw_req_ready_i && ptw_req_valid_o) begin
                next_state = PTW_PENDING;
            end
        end
        
        PTW_PENDING: begin
            if (ptw_resp_valid_i && ptw_resp_ready_o) begin
                next_state = UPDATE;
            end
        end
        
        UPDATE: begin
            next_state = RESPOND;
        end
        
        RESPOND: begin
            if (resp_ready_i && resp_valid_o) begin
                next_state = ACCEPT_REQ;
            end
        end
        
        default: begin
            next_state = ACCEPT_REQ;
        end
    endcase
end

// Next state logic and output control
always @(posedge clk) begin
    if (rst) begin
        req_ready_o       <= 1'b1;
        resp_valid_o      <= 1'b0;
        ptw_req_valid_o   <= 1'b0;
        ptw_resp_ready_o  <= 1'b0;
        lookup_en         <= 1'b0;
        update_en         <= 1'b0;
        lru_update_en     <= 1'b0;
    end else begin

        case (state)
        ACCEPT_REQ: begin
            if (req_valid_i && req_ready_o) begin
                req_ready_o <= 1'b0;
                lookup_en <= 1'b1;
            end else begin
                req_ready_o <= 1'b1;
            end
        end
        
        LOOKUP: begin
            // lookup_en <= 1'b1;
            if (hit && !perm_fault) begin
                resp_valid_o  <= 1'b1;
                lru_update_en <= 1'b1;
            end else if (hit && perm_fault) begin
                resp_valid_o  <= 1'b1;
            end else begin
                ptw_req_valid_o <= 1'b1;
            end
        end
        
        PTW_REQ: begin
            //ptw_req_valid_o <= 1'b1;
            if (ptw_req_ready_i && ptw_req_valid_o) begin
                ptw_req_valid_o  <= 1'b0;
                ptw_resp_ready_o <= 1'b1;
            end
        end
        
        PTW_PENDING: begin
            //ptw_resp_ready_o <= 1'b1;
            if (ptw_resp_valid_i && ptw_resp_ready_o) begin
                ptw_resp_ready_o <= 1'b0;
            end
        end
        
        UPDATE: begin
            update_en    <= 1'b1;
            resp_valid_o <= 1'b1;
        end
        
        RESPOND: begin
            //lru_update_en <= 1'b0;
            //resp_valid_o <= 1'b1;
            if (resp_ready_i && resp_valid_o) begin
                resp_valid_o  <= 1'b0;
                req_ready_o   <= 1'b1;
            end
        end
        
        default: begin
            req_ready_o       <= 1'b1;
            resp_valid_o      <= 1'b0;
            ptw_req_valid_o   <= 1'b0;
            ptw_resp_ready_o  <= 1'b0;
        end
    endcase
    end    
end

endmodule