// tlb_lookup.v
// TLB查找逻辑模块

`include "tlb_params.vh"

module tlb_lookup (
    // Input virtual address
    input [31:0] vaddr,
    input access_type,
    
    // TLB entry data from storage
    input                 tlb_valid     [0:NUM_WAYS-1],
    input [19:0]          tlb_vpn       [0:NUM_WAYS-1],
    input [19:0]          tlb_ppn       [0:NUM_WAYS-1],
    input [1:0]           tlb_perms     [0:NUM_WAYS-1],
    
    // Lookup results
    output [19:0] vpn,
    output [SET_INDEX_BITS-1:0] set_index,
    output [11:0] page_offset,
    output hit,
    output [1:0] hit_way,
    output [19:0] hit_ppn,
    output [1:0] hit_perms,
    output perm_fault
);

// Extract fields from virtual address
assign vpn         = vaddr[31:12];
assign set_index   = vaddr[SET_INDEX_BITS-1+12:12];
assign page_offset = vaddr[11:0];

// Generate match signals within the set
wire [NUM_WAYS-1:0] match;
generate
    for (genvar i = 0; i < NUM_WAYS; i = i + 1) begin : match_gen
        assign match[i] = tlb_valid[i] && (tlb_vpn[i] == vpn);
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
assign hit_ppn = match[0] ? tlb_ppn[0] :
                 match[1] ? tlb_ppn[1] :
                 match[2] ? tlb_ppn[2] :
                 match[3] ? tlb_ppn[3] : 20'd0;

assign hit_perms = match[0] ? tlb_perms[0] :
                   match[1] ? tlb_perms[1] :
                   match[2] ? tlb_perms[2] :
                   match[3] ? tlb_perms[3] : 2'b00;

// Permission check
assign perm_fault = (access_type == 1'b0 && !hit_perms[0]) ||  // Read permission
                    (access_type == 1'b1 && !hit_perms[1]);     // Write permission

endmodule