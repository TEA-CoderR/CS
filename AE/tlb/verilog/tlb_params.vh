// tlb_params.vh

`ifndef TLB_PARAMS_VH
`define TLB_PARAMS_VH

// TLB parameters
parameter NUM_ENTRIES    = 64;      // Total number of entries
parameter NUM_WAYS       = 4;       // Number of ways (set-associative)
parameter NUM_SETS       = 16;      // Number of sets (64/4 = 16)
parameter LRU_BITS       = 4;       // LRU counter bit width
parameter SET_INDEX_BITS = 4;       // Set index bit width (log2(16) = 4)

// State definitions
parameter ACCEPT_REQ  = 3'd0;
parameter LOOKUP      = 3'd1;
parameter PTW_REQ     = 3'd2;
parameter PTW_PENDING = 3'd3;
parameter UPDATE      = 3'd4;
parameter RESPOND     = 3'd5;

`endif