module tb;
  localparam ENTRIES   = 4;
  localparam VPN_WIDTH = 27;
  localparam PPN_WIDTH = 27;
  localparam ASID_WIDTH= 8;

  logic clk = 0, rst_n = 0;

  // DUT IO
  logic req_valid;
  logic [VPN_WIDTH-1:0] req_vpn;
  logic [ASID_WIDTH-1:0] req_asid;
  logic hit;
  logic [$clog2(ENTRIES)-1:0] hit_index;
  logic [PPN_WIDTH-1:0] hit_ppn;
  logic hit_dirty, hit_accessed, hit_global;
  logic [2:0] hit_perm;

  logic inval_all, inval_vpn_valid;
  logic [VPN_WIDTH-1:0] inval_vpn;
  logic [ASID_WIDTH-1:0] inval_asid;

  logic write_valid, write_idx_valid;
  logic [$clog2(ENTRIES)-1:0] write_idx;
  logic [VPN_WIDTH-1:0] write_vpn;
  logic [PPN_WIDTH-1:0] write_ppn;
  logic write_dirty, write_accessed, write_global;
  logic [2:0] write_perm;
  logic [ASID_WIDTH-1:0] write_asid;
  logic [$clog2(ENTRIES)-1:0] repl_index;

  tlb_simple #(
    .ENTRIES(ENTRIES),
    .VPN_WIDTH(VPN_WIDTH),
    .PPN_WIDTH(PPN_WIDTH),
    .USE_ASID(1),
    .ASID_WIDTH(ASID_WIDTH)
  ) dut (
    .clk, .rst_n,
    .req_valid, .req_vpn, .req_asid,
    .hit, .hit_index, .hit_ppn, .hit_dirty, .hit_accessed, .hit_perm, .hit_global,
    .inval_all, .inval_vpn_valid, .inval_vpn, .inval_asid,
    .write_valid, .write_idx_valid, .write_idx,
    .write_vpn, .write_ppn, .write_dirty, .write_accessed, .write_perm, .write_global, .write_asid,
    .repl_index
  );

  always #5 clk = ~clk;

  initial begin
  rst_n = 0;
  inval_all = 0; inval_vpn_valid = 0;
  write_valid = 0; req_valid = 0;

  // 等待几个周期 (不用 @(posedge clk))
  repeat (4) begin
    #10; // 用延时代替
  end
  rst_n = 1;

  // 写一条映射
  #10;
  write_valid = 1;
  write_idx_valid = 0;
  write_vpn = 27'h12345;
  write_ppn = 27'h00ABC;
  write_perm = 3'b111;
  write_dirty = 0;
  write_accessed = 0;
  write_global = 0;
  write_asid = 8'h01;
  #10;
  write_valid = 0;

  // 查找命中
  #10;
  req_vpn = 27'h12345;
  req_asid = 8'h01;
  req_valid = 1;
  #10;

  // 失效该VPN
  inval_vpn_valid = 1;
  inval_vpn = 27'h12345;
  inval_asid = 8'h01;
  #10;
  inval_vpn_valid = 0;

  // 再查找 -> miss
  #10;

  $finish;
end

endmodule
