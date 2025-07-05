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
    input [31:0] vaddr_i,       // Virtual address input
    input access_type_i         // Access_type: 0 -> read, 1 -> write
    input req_valid_i,          // Request valid
    output reg [31:0] paddr_o,  // Physical address output
    output reg resp_valid_o,    // Response valid
    output reg hit_o,           // TLB hit
    output reg fault_o,         // Access fault

    // PTW Interface
    output reg ptw_req_o,       // PTW request
    output reg [31:0] ptw_vaddr_o,// PTW virtual address
    input ptw_resp_valid_i,     // PTW response valid
    input [31:0] ptw_pte_i,     // Page table entry
    input ptw_fault_i           // PTW fault
);

// TLB parameters
parameter NUM_ENTRIES = 64;     // Total number of entries
parameter NUM_WAYS = 4;         // Number of ways (set-associative)
parameter NUM_SETS = 16;        // Number of sets (64/4 = 16)
parameter LRU_BITS = 4;         // LRU counter bit width
parameter SET_INDEX_BITS = 4;   // Set index bit width (log2(16) = 4)

// TLB storage structure
typedef struct packed {
    logic valid;                // Valid bit
    logic [19:0] vpn;           // Virtual page number (upper 20 bits)
    logic [19:0] ppn;           // Physical page number
    logic [1:0] perms;          // Permission bits (WR)
    logic [LRU_BITS-1:0] lru_count; // LRU counter
} tlb_entry_t;

tlb_entry_t tlb_entries [0:NUM_SETS-1][0:NUM_WAYS-1];   // Storage array [set][way]

// State definitions
typedef enum logic [1:0]{
    ACCEPT_REQ,
    LOOKUP,
    PTW_PENDING,
    UPDATE
} state_t;

// Internal registers
state_t state, next_state;
reg [31:0] vaddr_reg;
reg [2:0] access_type_reg;
reg [31:0] pte_reg;             // Store PTE from PTW

// Lookup logic signals
wire [19:0] vpn;                        // Virtual page number
wire [SET_INDEX_BITS-1:0] set_index;    // Set index
wire [11:0] page_offset;                // Page offset

// Intra-set match signals
wire [NUM_WAYS-1:0] match;
wire hit;
wire hit_way;
wire [19:0] hit_ppn;
wire [2:0] hit_perms;
wire perm_fault;

// LRU information within set
reg [1:0] replace_way;       // Replacement way
reg [LRU_BITS-1:0] min_lru_value;
reg [LRU_BITS-1:0] max_lru_value;

// ===================================================================
// TLB Lookup Logic (Combinational Logic)
// ===================================================================

// Vpn extraction
assign vpn = vaddr_reg[31:12];

// Set index extraction
assign set_index = vaddr_reg[SET_INDEX_BITS-1+12:12];

// Page offset extraction
assign page_offset = vaddr_reg[11:0];

// Generate match signals within the set
generate
    for (genvar i = 0; i < NUM_WAYS; i = i + 1) begin : match_gen
        assign match[i] = tlb_entries[set_index][i].valid && 
                         (tlb_entries[set_index][i].vpn == vpn);
    end
endgenerate

// Hit detection
assign hit = |match;

// Hit way selection
assign hit_way = match[0] ? 2'd0 :
                 match[1] ? 2'd1 :
                 match[2] ? 2'd2 :
                 match[3] ? 2'd3 : 2'd0;

// Hit PPN and permissions
assign hit_ppn = match[0] ? tlb_entries[set_index][0].ppn :
                 match[1] ? tlb_entries[set_index][1].ppn :
                 match[2] ? tlb_entries[set_index][2].ppn :
                 match[3] ? tlb_entries[set_index][3].ppn : 20'd0;
                 
assign hit_perms = match[0] ? tlb_entries[set_index][0].perms :
                   match[1] ? tlb_entries[set_index][1].perms :
                   match[2] ? tlb_entries[set_index][2].perms :
                   match[3] ? tlb_entries[set_index][3].perms : 2'd0;

// Permission check
assign perm_fault = 
    // Read requires read permission
    (access_type_reg == 1'b0 && !hit_perms[0]) || 
    // Write requires write permission
    (access_type_reg == 1'b1 && !hit_perms[1]);

// ===================================================================
// Main State Machine
// ===================================================================
always @(posedge clk) begin
    if (rst) begin
        next_state <= ACCEPT_REQ;
        resp_valid_o <= 0;
        ptw_req_o <= 0;
        hit_o <= 0;
        fault_o <= 0;

        // Reset Internal registers
        vaddr_reg <= 0;
        access_type_reg <= 0;
        pte_reg <= 0;
        
        // Reset TLB entries
        integer s, w;
        for (s = 0; s < NUM_SETS; s = s + 1) begin
            for (w = 0; w < NUM_WAYS; w = w + 1) begin
                tlb_entries[s][w].valid <= 0;
                tlb_entries[s][w].vpn <= 0;
                tlb_entries[s][w].ppn <= 0;
                tlb_entries[s][w].perms <= 0;
                tlb_entries[s][w].lru_count <= 0;
            end
        end
    end else begin
        state <= next_state;
        
        case (state)
            ACCEPT_REQ: begin
                resp_valid_o <= 0;
                if (req_valid_i) begin
                    vaddr_reg <= vaddr_i;
                    access_type_reg <= access_type_i;
                    
                    next_state <= LOOKUP;
                end
            end
            
            LOOKUP: begin
                if (hit && !perm_fault) begin
                    // TLB hit with correct permissions
                    paddr_o <= {hit_ppn, page_offset};
                    hit_o <= 1;
                    fault_o <= 0;
                    resp_valid_o <= 1;
                    next_state <= ACCEPT_REQ;
                    
                    // Update LRU counter: increment for hit way
                    tlb_entries[set_index][hit_way].lru_count <= 
                        tlb_entries[set_index][hit_way].lru_count + 1;
                end
                else if (hit && perm_fault) begin
                    // Permission fault
                    hit_o <= 1;
                    fault_o <= 1;
                    resp_valid_o <= 1;

                    next_state <= ACCEPT_REQ;
                end
                else begin
                    // TLB miss, initiate page table walk
                    ptw_req_o <= 1;
                    ptw_vaddr_o <= vaddr_reg;

                    next_state <= PTW_PENDING;
                end
            end
            
            PTW_PENDING: begin
                ptw_req_o <= 0; // PTW request is one-cycle pulse
                
                if (ptw_resp_valid_i) begin
                    if (ptw_fault_i) begin
                        // PTW fault (e.g., page fault)
                        hit_o <= 0;
                        fault_o <= 1;
                        resp_valid_o <= 1;

                        next_state <= ACCEPT_REQ;
                    end else begin
                        // Success, store PTE
                        pte_reg <= ptw_pte_i;

                        next_state <= UPDATE;
                    end
                end
            end
            
            UPDATE: begin
                // Permission check
                if ((access_type_reg == 1'b0 && !pte_reg[0]) ||
                 (access_type_reg == 1'b1 && !pte_reg[1])) begin
                    hit_o <= 0;
                    fault_o <= 1;
                    resp_valid_o <= 1;

                    next_state <= ACCEPT_REQ;
                end else begin
                    // Intra-set LRU calculation: find way with minimum LRU value
                    replace_way = 0;
                    min_lru_value = tlb_entries[set_index][0].lru_count;
                    max_lru_value = min_lru_value;
                    
                    integer i;
                    for (i = 1; i < NUM_WAYS; i = i + 1) begin
                        if (tlb_entries[set_index][i].lru_count < min_lru_value) begin
                            min_lru_value = tlb_entries[set_index][i].lru_count;
                            replace_way = i;
                        end
                        if (tlb_entries[set_index][i].lru_count > max_lru_value) begin
                            max_lru_value = tlb_entries[set_index][i].lru_count;
                        end
                    end

                    // Update TLB entry (replace way with lowest LRU)
                    tlb_entries[set_index][replace_way].valid <= 1'b1;
                    tlb_entries[set_index][replace_way].vpn <= vpn;
                    tlb_entries[set_index][replace_way].ppn <= pte_reg[31:12];
                    tlb_entries[set_index][replace_way].perms <= pte_reg[1:0];
                    tlb_entries[set_index][replace_way].lru_count <= max_lru_value; // New entry LRU = max_lru_value
                    
                    // Output physical address
                    paddr_o <= {pte_reg[31:12], page_offset};
                    hit_o <= 0;    // Indicate it was a TLB miss but handled
                    fault_o <= 0;
                    resp_valid_o <= 1;

                    next_state <= ACCEPT_REQ;
                end

            end
        endcase
    end
end

endmodule