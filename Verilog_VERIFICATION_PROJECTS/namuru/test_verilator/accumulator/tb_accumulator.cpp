/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012

Just a simple experiment of writing testbenche for accumulator.v. It's only example of
testbench. Further research must be done to check accumulator.v correctness!
*/

#include "Vaccumulator.h"
#include "verilated.h"
#include "verilated_vcd_c.h"


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vaccumulator* top = new Vaccumulator;
  // init trace dump
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace (tfp, 99);
  tfp->open ("accumulator.vcd");
  // initialize simulation inputs
  top->clk              = 1;
  top->rstn             = 0;
  top->sample_enable    = 0;
  top->dump_enable      = 0;
  top->carrier_mix_sign = 0;
  top->carrier_mix_mag  = 0;
  // run simulation for 100 clock periods
  for (i=0; i<110; i++) {
    if (i==4){
      top->rstn             = 1;
      top->dump_enable      = 0;
      top->code             = 1;
      top->carrier_mix_sign = 1;
      top->carrier_mix_mag  = 3;
    }
    else if (i==20) {
      top->carrier_mix_mag  = 1;
    }
    else if (i==28) {
      top->carrier_mix_sign = 0;
      top->carrier_mix_mag  = 2;
    }
    else if (i==48) {
      top->dump_enable      = 1;
    }
    else if (i==50) {
      top->dump_enable      = 0;
    }
    // dump variables into VCD file and toggle clock
    for (clk=0; clk<2; clk++) {
      tfp->dump ((2*i+clk)*12.5);
      top->clk = !top->clk;
      top->eval ();
    }
    top->sample_enable = !top->sample_enable;

    if (Verilated::gotFinish())  exit(0);
  }
  tfp->close();
  exit(0);
}
