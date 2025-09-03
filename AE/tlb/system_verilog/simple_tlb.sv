module simple_tlb #(
    parameter ENTRY_NUM = 16,           // TLB项数
    parameter VPN_WIDTH = 20,          // 虚拟页号位宽
    parameter PPN_WIDTH = 20,          // 物理页号位宽
    parameter PAGE_OFFSET_WIDTH = 12   // 页内偏移
)(
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic [VPN_WIDTH+PAGE_OFFSET_WIDTH-1:0] virt_addr,
    input  logic                         write_en,
    input  logic [$clog2(ENTRY_NUM)-1:0] write_index,
    input  logic [VPN_WIDTH-1:0]         write_vpn,
    input  logic [PPN_WIDTH-1:0]         write_ppn,

    output logic                         hit,
    output logic [PPN_WIDTH+PAGE_OFFSET_WIDTH-1:0] phys_addr
);

    // TLB存储表项
    typedef struct packed {
        logic valid;
        logic [VPN_WIDTH-1:0] vpn;
        logic [PPN_WIDTH-1:0] ppn;
    } tlb_entry_t;

    tlb_entry_t tlb[ENTRY_NUM];

    // 拆分输入虚拟地址
    logic [VPN_WIDTH-1:0] vpn_in;
    logic [PAGE_OFFSET_WIDTH-1:0] page_offset;

    assign vpn_in = virt_addr[VPN_WIDTH+PAGE_OFFSET_WIDTH-1:PAGE_OFFSET_WIDTH];
    assign page_offset = virt_addr[PAGE_OFFSET_WIDTH-1:0];

    // 命中检测
    always_comb begin
        hit = 0;
        phys_addr = '0;
        foreach (tlb[i]) begin
            if (tlb[i].valid && tlb[i].vpn == vpn_in) begin
                hit = 1;
                phys_addr = {tlb[i].ppn, page_offset};
            end
        end
    end

    // 写入TLB
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            foreach (tlb[i]) tlb[i].valid <= 0;
        end else if (write_en) begin
            tlb[write_index].valid <= 1;
            tlb[write_index].vpn   <= write_vpn;
            tlb[write_index].ppn   <= write_ppn;
        end
    end

endmodule