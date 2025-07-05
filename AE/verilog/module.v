module tlb (
    input clk,
    input rst_n,
    
    // Processor Interface
    input [31:0] vaddr_i,       // Virtual address
    input [2:0] access_type_i,  // Access type: 000 - fetch, 001 - read, 010 - write
    input req_valid_i,          // Request valid
    output reg [31:0] paddr_o,  // Physical address
    output reg resp_valid_o,    // Response valid
    output reg hit_o,           // TLB hit
    output reg fault_o,         // Access fault
    
    // PTW Interface
    output reg ptw_req_o,       // PTW request
    output reg [31:0] ptw_vaddr_o, // PTW virtual address
    input ptw_resp_valid_i,     // PTW response valid
    input [31:0] ptw_pte_i,     // Page table entry
    input ptw_fault_i           // PTW fault
);

// TLB parameters
parameter NUM_ENTRIES = 64;     // Total number of entries
parameter NUM_WAYS = 4;         // Number of ways (set-associative)
parameter NUM_SETS = 16;        // Number of sets (64/4 = 16)
localparam LRU_BITS = 4;        // LRU counter bit width
localparam SET_INDEX_BITS = 4;  // Set index bit width (log2(16) = 4)

// TLB storage structure
typedef struct packed {
    logic valid;                // Valid bit
    logic [19:0] ppn;           // Physical page number
    logic [19:0] vpn;           // Virtual page number (upper 20 bits)
    logic [2:0] perms;          // Permission bits (WRX)
    logic [LRU_BITS-1:0] lru_count; // LRU counter
} tlb_entry_t;

tlb_entry_t tlb_entries [0:NUM_SETS-1][0:NUM_WAYS-1]; // Storage array [set][way]

// State definitions
typedef enum logic [1:0] {
    IDLE,
    LOOKUP,
    PTW_PENDING,
    UPDATE
} state_t;

// Internal registers
state_t state, next_state;
reg [31:0] vaddr_reg;
reg [2:0] access_type_reg;
reg [SET_INDEX_BITS-1:0] set_index_reg; // Set index for current request
reg [1:0] hit_way_reg;           // Hit way
reg [1:0] replace_way_reg;       // Replacement way
reg [31:0] pte_reg;              // PTE from PTW

// Lookup logic signals
wire [19:0] vpn = vaddr_i[31:12]; // Virtual page number
wire [SET_INDEX_BITS-1:0] set_index = vpn[SET_INDEX_BITS-1:0]; // Set index
wire [11:0] page_offset = vaddr_i[11:0]; // Page offset

// Intra-set match signals
wire [NUM_WAYS-1:0] match;
wire hit;
wire hit_way;
wire [19:0] hit_ppn;
wire [2:0] hit_perms;
wire perm_fault;

// LRU information within set
reg [1:0] min_lru_way;
reg [LRU_BITS-1:0] min_lru_value;

// ===================================================================
// TLB Lookup Logic (Combinational Logic)
// ===================================================================

// Generate match signals within the set
generate
    for (genvar i = 0; i < NUM_WAYS; i = i + 1) begin : match_gen
        assign match[i] = tlb_entries[set_index][i].valid && 
                         (tlb_entries[set_index][i].vpn == vpn);
    end
endgenerate

// Hit detection
assign hit = |match;

// Hit way selection (priority encoder)
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
                   match[3] ? tlb_entries[set_index][3].perms : 3'd0;

// Permission check
assign perm_fault = 
    // Instruction fetch requires execute permission
    (access_type_i == 3'b000 && !hit_perms[0]) || 
    // Read requires read permission
    (access_type_i == 3'b001 && !hit_perms[1]) || 
    // Write requires write permission
    (access_type_i == 3'b010 && !hit_perms[2]);

// Intra-set LRU calculation: find way with minimum LRU value
always @(*) begin
    min_lru_way = 0;
    min_lru_value = tlb_entries[set_index][0].lru_count;
    
    for (int i = 1; i < NUM_WAYS; i = i + 1) begin
        if (tlb_entries[set_index][i].lru_count < min_lru_value) begin
            min_lru_value = tlb_entries[set_index][i].lru_count;
            min_lru_way = i;
        end
    end
end

// ===================================================================
// Main State Machine
// ===================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        resp_valid_o <= 0;
        ptw_req_o <= 0;
        hit_o <= 0;
        fault_o <= 0;
        
        // Reset TLB entries
        integer s, w;
        for (s = 0; s < NUM_SETS; s = s + 1) begin
            for (w = 0; w < NUM_WAYS; w = w + 1) begin
                tlb_entries[s][w].valid <= 0;
                tlb_entries[s][w].ppn <= 0;
                tlb_entries[s][w].vpn <= 0;
                tlb_entries[s][w].perms <= 0;
                tlb_entries[s][w].lru_count <= 0;
            end
        end
    end else begin
        state <= next_state;
        
        case (state)
            IDLE: begin
                resp_valid_o <= 0;
                if (req_valid_i) begin
                    vaddr_reg <= vaddr_i;
                    access_type_reg <= access_type_i;
                    set_index_reg <= set_index; // Latch set index
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
                    next_state <= IDLE;
                    
                    // Update LRU counter: increment for hit way
                    tlb_entries[set_index_reg][hit_way].lru_count <= 
                        tlb_entries[set_index_reg][hit_way].lru_count + 1;
                end
                else if (hit && perm_fault) begin
                    // Permission fault
                    hit_o <= 1;
                    fault_o <= 1;
                    resp_valid_o <= 1;
                    next_state <= IDLE;
                    
                    // Optional: log error information
                end
                else begin
                    // TLB miss, initiate page table walk
                    ptw_req_o <= 1;
                    ptw_vaddr_o <= vaddr_i;
                    hit_way_reg <= hit_way;          // Store hit way (not used)
                    replace_way_reg <= min_lru_way;  // Store replacement way
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
                        next_state <= IDLE;
                    end else begin
                        // Store PTE
                        pte_reg <= ptw_pte_i;
                        next_state <= UPDATE;
                    end
                end
            end
            
            UPDATE: begin
                // Update TLB entry (replace way with lowest LRU)
                tlb_entries[set_index_reg][replace_way_reg].valid <= 1'b1;
                tlb_entries[set_index_reg][replace_way_reg].vpn <= vpn;
                tlb_entries[set_index_reg][replace_way_reg].ppn <= pte_reg[31:12];
                tlb_entries[set_index_reg][replace_way_reg].perms <= pte_reg[2:0];
                tlb_entries[set_index_reg][replace_way_reg].lru_count <= 0; // New entry LRU = 0
                
                // Output physical address
                paddr_o <= {pte_reg[31:12], page_offset};
                hit_o <= 0;    // Indicate it was a TLB miss but handled
                fault_o <= 0;
                resp_valid_o <= 1;
                next_state <= IDLE;
            end
        endcase
    end
end

// // Next state logic
// always_comb begin
//     next_state = state; // Default to stay in current state
    
//     // State transition logic
//     case (state)
//         IDLE: 
//             if (req_valid_i) 
//                 next_state = LOOKUP;
        
//         LOOKUP: 
//             if (hit) 
//                 next_state = IDLE;          // Hit, done
//             else 
//                 next_state = PTW_PENDING;   // Miss, start PTW
        
//         PTW_PENDING: 
//             if (ptw_resp_valid_i) 
//                 next_state = (ptw_fault_i) ? IDLE : UPDATE;
        
//         UPDATE: 
//             next_state = IDLE;
//     endcase
// end

endmodule
