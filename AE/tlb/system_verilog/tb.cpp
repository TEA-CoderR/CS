#include "Vsimple_tlb.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

vluint64_t main_time = 0;  // 仿真时间

// 时钟翻转函数
void tick(Vsimple_tlb* top, VerilatedVcdC* tfp) {
    top->clk = 0;
    top->eval();
    tfp->dump(main_time++);
    
    top->clk = 1;
    top->eval();
    tfp->dump(main_time++);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Vsimple_tlb* top = new Vsimple_tlb;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("dump.vcd");

    // 初始化输入
    top->rst_n = 0;
    top->write_en = 0;
    top->virt_addr = 0;
    top->write_index = 0;
    top->write_vpn = 0;
    top->write_ppn = 0;

    // 复位
    tick(top, tfp);
    top->rst_n = 1;
    tick(top, tfp);

    // 写入 TLB: index=0, VPN=0x12345, PPN=0xABCDE
    top->write_en = 1;
    top->write_index = 0;
    top->write_vpn = 0x12345;
    top->write_ppn = 0xABCDE;
    tick(top, tfp);
    top->write_en = 0;
    tick(top, tfp);

    // 查询命中: virt_addr = {VPN=0x12345, offset=0x111}
    top->virt_addr = ((uint64_t)0x12345 << 12) | 0x111;
    tick(top, tfp);
    printf("Hit=%d, PhysAddr=0x%llX (expect hit=1)\n",
           top->hit, (unsigned long long)top->phys_addr);

    // 查询未命中: virt_addr = {VPN=0x99999, offset=0x111}
    top->virt_addr = ((uint64_t)0x99999 << 12) | 0x111;
    tick(top, tfp);
    printf("Hit=%d, PhysAddr=0x%llX (expect hit=0)\n",
           top->hit, (unsigned long long)top->phys_addr);

    // 结束仿真
    tfp->close();
    delete tfp;
    delete top;
    return 0;
}


