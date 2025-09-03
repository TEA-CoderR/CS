/*
 * Module: TLB (Translation Lookaside Buffer)
 * 
 * Description:
 * This module implements a 64-entry, 4-way set-associative TLB for virtual-to-physical
 * address translation in a processor memory management unit (MMU). It supports two
 * types of memory accesses: read, and write, each with corresponding
 * permission checks (read, write).
 * 
 * Features:
 * - Set-associative TLB with 16 sets and 4 ways per set
 * - LRU (Least Recently Used) replacement policy implemented with counters
 * - Permissions checking to detect access faults (read, write)
 * - Integration with a Page Table Walker (PTW) to handle TLB misses:
 *      - Sends PTW requests on misses
 *      - Updates TLB entries on PTW response
 *      - Handles PTW faults (e.g., page faults)
 * - Outputs physical address, hit signal, fault indication, and response validity
 * 
 * Interfaces:
 * - Processor Interface:
 *      - Inputs: virtual address, access type, request valid
 *      - Outputs: physical address, hit, fault, response valid
 * - PTW Interface:
 *      - Outputs: PTW request, PTW virtual address
 *      - Inputs: PTW response valid, page table entry, PTW fault
 * 
 * Operation:
 * Upon receiving a valid request, the module looks up the TLB using the virtual
 * page number and set index. If a valid matching entry with appropriate permissions
 * is found, it outputs the translated physical address with a hit signal.
 * Otherwise, it initiates a PTW request. When the PTW responds, the TLB entry is
 * updated with the new page table entry, and the physical address is output.
 * 
 * Reset behavior:
 * On reset, all TLB entries are invalidated and internal state is cleared.
 * 
 */

module tlb (
    input clk,
    input rst,

    // Processor Interface
    /*---------------------Accept request-----------------------------*/
    input req_valid_i,              
    output reg req_ready_o,         
    input [31:0] vaddr_i,           
    input access_type_i,           

    /*----------------------Send response-----------------------------*/
    output reg resp_valid_o,        
    input resp_ready_i,             
    output reg [31:0] paddr_o,      
    output reg hit_o,               
    output reg fault_o,             

    // PTW Interface
    /*----------------------Send request------------------------------*/
    output reg ptw_req_valid_o,     
    input ptw_req_ready_i,          
    output reg [31:0] ptw_vaddr_o,  

    /*---------------------Accept response----------------------------*/
    input ptw_resp_valid_i,         
    output reg ptw_resp_ready_o,    
    input [31:0] ptw_pte_i          
);

// TLB parameters
parameter NUM_ENTRIES     = 64;    
parameter NUM_WAYS        = 4;     
parameter NUM_SETS        = 16;    
parameter LRU_BITS        = 4;     
parameter SET_INDEX_BITS  = 4;     

// ===================================================================
// TLB storage structure
// ===================================================================
reg               tlb_valid    [0:NUM_SETS-1][0:NUM_WAYS-1];
reg [19:0]        tlb_vpn      [0:NUM_SETS-1][0:NUM_WAYS-1];
reg [19:0]        tlb_ppn      [0:NUM_SETS-1][0:NUM_WAYS-1];
reg [1:0]         tlb_perms    [0:NUM_SETS-1][0:NUM_WAYS-1];
reg [LRU_BITS-1:0]tlb_lru_count[0:NUM_SETS-1][0:NUM_WAYS-1];

// ===================================================================
// State definitions
// ===================================================================
localparam [2:0]
    ACCEPT_REQ  = 3'd0,
    LOOKUP      = 3'd1,
    PTW_REQ     = 3'd2,
    PTW_PENDING = 3'd3,
    UPDATE      = 3'd4,
    RESPOND     = 3'd5;

reg [2:0]  state, next_state;
reg [31:0] vaddr_reg;
reg        access_type_reg;
reg [31:0] pte_reg;             

// Lookup logic signals
wire [19:0] vpn        = vaddr_reg[31:12];
wire [SET_INDEX_BITS-1:0] set_index = vaddr_reg[SET_INDEX_BITS-1+12:12];
wire [11:0] page_offset = vaddr_reg[11:0];

// ===================================================================
// Add initialization for tlb entries
// ===================================================================
integer s, w;
initial begin
    for (s = 0; s < NUM_SETS; s = s + 1) begin
        for (w = 0; w < NUM_WAYS; w = w + 1) begin
            tlb_valid[s][w]     = 1'b0;
            tlb_vpn[s][w]       = 20'd0;
            tlb_ppn[s][w]       = 20'd0;
            tlb_perms[s][w]     = 2'd0;
            tlb_lru_count[s][w] = {LRU_BITS{1'b0}};
        end
    end
end

// ===================================================================
// TLB Lookup Logic (Combinational Logic)
// ===================================================================
wire [NUM_WAYS-1:0] match;
assign match[0] = tlb_valid[set_index][0] && (tlb_vpn[set_index][0] == vpn);
assign match[1] = tlb_valid[set_index][1] && (tlb_vpn[set_index][1] == vpn);
assign match[2] = tlb_valid[set_index][2] && (tlb_vpn[set_index][2] == vpn);
assign match[3] = tlb_valid[set_index][3] && (tlb_vpn[set_index][3] == vpn);

wire hit = |match;

wire [1:0] hit_way = match[0] ? 2'd0 :
                     match[1] ? 2'd1 :
                     match[2] ? 2'd2 :
                     match[3] ? 2'd3 : 2'd0;

wire [19:0] hit_ppn = match[0] ? tlb_ppn[set_index][0] :
                      match[1] ? tlb_ppn[set_index][1] :
                      match[2] ? tlb_ppn[set_index][2] :
                      match[3] ? tlb_ppn[set_index][3] : 20'd0;

wire [1:0] hit_perms = match[0] ? tlb_perms[set_index][0] :
                       match[1] ? tlb_perms[set_index][1] :
                       match[2] ? tlb_perms[set_index][2] :
                       match[3] ? tlb_perms[set_index][3] : 2'd0;

wire perm_fault = ((access_type_reg == 1'b0) && !hit_perms[0]) ||
                  ((access_type_reg == 1'b1) && !hit_perms[1]);

// ===================================================================
// Main State Machine
// ===================================================================
always @(posedge clk) begin
    integer i, replace_way, min_lru, max_lru;
    if (rst) begin
        state <= ACCEPT_REQ;
        req_ready_o <= 1'b1;
        resp_valid_o <= 1'b0;
        paddr_o <= 32'd0;
        hit_o <= 1'b0;
        fault_o <= 1'b0;
        ptw_req_valid_o <= 1'b0;
        ptw_vaddr_o <= 32'd0;
        ptw_resp_ready_o <= 1'b0;
        vaddr_reg <= 32'd0;
        access_type_reg <= 1'b0;
        pte_reg <= 32'd0;
    end else begin
        state <= next_state;
        case (state)
            ACCEPT_REQ: begin
                /*---------------------Accept processor request----------------*/
                if (req_valid_i) begin
                    vaddr_reg <= vaddr_i;
                    access_type_reg <= access_type_i;
                    req_ready_o <= 1'b0;
                    next_state <= LOOKUP;
                end
            end

            LOOKUP: begin
                /*-----------------------TLB Lookup----------------------------*/
                if (hit && !perm_fault) begin
                    paddr_o <= {hit_ppn, page_offset};
                    hit_o <= 1'b1;
                    fault_o <= 1'b0;
                    resp_valid_o <= 1'b1;
                    next_state <= RESPOND;
                    tlb_lru_count[set_index][hit_way] <= tlb_lru_count[set_index][hit_way] + 1'b1;
                end
                else if (hit && perm_fault) begin
                    paddr_o <= 32'd0;
                    hit_o <= 1'b1;
                    fault_o <= 1'b1;
                    resp_valid_o <= 1'b1;
                    next_state <= RESPOND;
                end
                else begin
                    /*-------------------TLB Miss: Send PTW request---------------*/
                    ptw_vaddr_o <= vaddr_reg;
                    ptw_req_valid_o <= 1'b1;
                    next_state <= PTW_REQ;
                end
            end

            PTW_REQ: begin
                /*-------------------Wait PTW ready----------------------------*/
                if (ptw_req_ready_i) begin
                    ptw_req_valid_o <= 1'b0;
                    ptw_resp_ready_o <= 1'b1;
                    next_state <= PTW_PENDING;
                end
            end

            PTW_PENDING: begin
                /*-------------------Accept PTW response----------------------*/
                if (ptw_resp_valid_i) begin
                    pte_reg <= ptw_pte_i;
                    ptw_resp_ready_o <= 1'b0;
                    next_state <= UPDATE;
                end
            end

            UPDATE: begin
                /*-------------------Update TLB Entry-------------------------*/
                if (((access_type_reg == 1'b0) && !pte_reg[0]) ||
                    ((access_type_reg == 1'b1) && !pte_reg[1])) begin
                    paddr_o <= 32'd0;
                    fault_o <= 1'b1;
                end else begin
                    replace_way = 0;
                    min_lru = tlb_lru_count[set_index][0];
                    max_lru = min_lru;
                    for (i = 1; i < NUM_WAYS; i = i + 1) begin
                        if (tlb_lru_count[set_index][i] < min_lru) begin
                            min_lru = tlb_lru_count[set_index][i];
                            replace_way = i;
                        end
                        if (tlb_lru_count[set_index][i] > max_lru) begin
                            max_lru = tlb_lru_count[set_index][i];
                        end
                    end
                    tlb_valid[set_index][replace_way]     <= 1'b1;
                    tlb_vpn[set_index][replace_way]       <= vpn;
                    tlb_ppn[set_index][replace_way]       <= pte_reg[31:12];
                    tlb_perms[set_index][replace_way]     <= pte_reg[1:0];
                    tlb_lru_count[set_index][replace_way] <= max_lru;
                    paddr_o <= {pte_reg[31:12], page_offset};
                    fault_o <= 1'b0;
                end
                hit_o <= 1'b0;
                resp_valid_o <= 1'b1;
                next_state <= RESPOND;
            end

            RESPOND: begin
                /*-------------------Send response back to processor----------*/
                if (resp_ready_i) begin
                    resp_valid_o <= 1'b0;
                    req_ready_o <= 1'b1;
                    next_state <= ACCEPT_REQ;
                end
            end
        endcase
    end
end

endmodule
