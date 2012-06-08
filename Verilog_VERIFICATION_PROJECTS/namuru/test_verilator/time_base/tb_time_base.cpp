/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012
*/

#include "Vtime_base.h"
#include "verilated.h"
#include "verilated_vcd_c.h"


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vtime_base* top = new Vtime_base;
  // init trace dump
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace (tfp, 99);
  tfp->open ("time_base.vcd");
  // initialize simulation inputs
  top->clk          = 1;
  top->rstn         = 0;
  top->tic_divide   = 0;
  top->accum_divide = 0;
  // run simulation for 100 clock periods
  for (i=0; i<5001; i++) {
    if (i==5){
      top->rstn         = 1;
      top->tic_divide   = 255;
      top->accum_divide = 511;
    }
    else if (i==5000) {
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
