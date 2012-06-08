/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012

Just a simple experiment of writing testbenche for accumulator.v. It's only example of
testbench. Further research must be done to check accumulator.v correctness!

In this test all combinations of if_sign, if_mag and 
carrier_sign, carrier_mag are checked. Result must be checked manually.
*/

#include "Vcarrier_mixer.h"
#include "verilated.h"
#include "verilated_vcd_c.h"


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vcarrier_mixer* top = new Vcarrier_mixer;
  // init trace dump
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace (tfp, 99);
  tfp->open ("carrier_mixer.vcd");
  // initialize simulation inputs
  top->if_sign      = 0;
  top->if_mag       = 0;
  top->carrier_sign = 0;
  top->carrier_mag  = 0;
  // run simulation for 100 clock periods
  for (i=0; i<500; i++) {
    //carrier=-1:
    if (i==20){
      top->if_sign = 0;      top->if_mag = 0;      //if=-1;
      top->carrier_sign = 0; top->carrier_mag = 0; //carrier=-1;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==40) {
      top->if_sign = 0;      top->if_mag = 1;      //if=-3;
      top->carrier_sign = 0; top->carrier_mag = 0; //carrier=-1;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==60) {
      top->if_sign = 1;      top->if_mag = 0;      //if=+1;
      top->carrier_sign = 0; top->carrier_mag = 0; //carrier=-1;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==80) {
      top->if_sign = 1;      top->if_mag = 1;      //if=+3;
      top->carrier_sign = 0; top->carrier_mag = 0; //carrier=-1;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    //carrier=-2:
    else if (i==100){
      top->if_sign = 0;      top->if_mag = 0;      //if=-1;
      top->carrier_sign = 0; top->carrier_mag = 1; //carrier=-2;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==120) {
      top->if_sign = 0;      top->if_mag = 1;      //if=-3;
      top->carrier_sign = 0; top->carrier_mag = 1; //carrier=-2;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==140) {
      top->if_sign = 1;      top->if_mag = 0;      //if=+1;
      top->carrier_sign = 0; top->carrier_mag = 1; //carrier=-2;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==160) {
      top->if_sign = 1;      top->if_mag = 1;      //if=+3;
      top->carrier_sign = 0; top->carrier_mag = 1; //carrier=-2;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    //carrier=+1:
    else if (i==180){
      top->if_sign = 0;      top->if_mag = 0;      //if=-1;
      top->carrier_sign = 1; top->carrier_mag = 0; //carrier=+1;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==200) {
      top->if_sign = 0;      top->if_mag = 1;      //if=-3;
      top->carrier_sign = 1; top->carrier_mag = 0; //carrier=+1;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==220) {
      top->if_sign = 1;      top->if_mag = 0;      //if=+1;
      top->carrier_sign = 1; top->carrier_mag = 0; //carrier=+1;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==240) {
      top->if_sign = 1;      top->if_mag = 1;      //if=+3;
      top->carrier_sign = 1; top->carrier_mag = 0; //carrier=+1;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    //carrier=+2:
    else if (i==260){
      top->if_sign = 0;      top->if_mag = 0;      //if=-1;
      top->carrier_sign = 1; top->carrier_mag = 1; //carrier=+2;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==280) {
      top->if_sign = 0;      top->if_mag = 1;      //if=-3;
      top->carrier_sign = 1; top->carrier_mag = 1; //carrier=+2;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==300) {
      top->if_sign = 1;      top->if_mag = 0;      //if=+1;
      top->carrier_sign = 1; top->carrier_mag = 1; //carrier=+2;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==320) {
      top->if_sign = 1;      top->if_mag = 1;      //if=+3;
      top->carrier_sign = 1; top->carrier_mag = 1; //carrier=+2;
      // dump variables into VCD file
      top->eval ();
      tfp->dump (i);
    }
    else if (i==340) {
      top->eval ();
      tfp->dump(i);
    }


    if (Verilated::gotFinish())  exit(0);
  }
  tfp->close();
  exit(0);
}
