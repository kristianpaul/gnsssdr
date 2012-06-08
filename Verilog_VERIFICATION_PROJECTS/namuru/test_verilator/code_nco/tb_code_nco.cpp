/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012
After the test is made gtkwave window opens. hc_enable
periode (or frequency) must be manually checked with the expected value.
*/

#include "Vcode_nco.h"
#include "verilated.h"
#include "verilated_vcd_c.h"


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vcode_nco* top = new Vcode_nco;
  // init trace dump
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace (tfp, 99);
  tfp->open ("code_nco.vcd");
  // initialize simulation inputs
  top->clk        = 1;
  top->rstn       = 0;
  top->tic_enable = 0;
  top->f_control  = 0;
  // run simulation for 100 clock periods
  for (i=0; i<50010; i++) {
    if (i==5){
      top->rstn      = 1;
      top->f_control = 0x14F3775; //2.046 hc clock for 50 MHz system clock;
    }
    else if (i==50000) {
      top->tic_enable = 1;
    }
    else if (i==50005) {
      top->rstn = 0;
    }
    // dump variables into VCD file and toggle clock
    for (clk=0; clk<2; clk++) {
      tfp->dump ((2*i+clk)*10);
      top->clk = !top->clk;
      top->eval ();
    }

    if (Verilated::gotFinish())  exit(0);
  }
  tfp->close();
  exit(0);
}
