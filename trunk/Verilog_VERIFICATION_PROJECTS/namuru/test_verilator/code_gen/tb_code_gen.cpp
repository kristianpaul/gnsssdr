/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012
Just a simple test of code generator.
*/

#include "Vcode_gen.h"
#include "Vcode_nco.h"
#include "verilated.h"
#include "verilated_vcd_c.h"


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vcode_gen* top = new Vcode_gen;
  Vcode_nco* sub_top = new Vcode_nco;
  // init trace dump
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace (tfp, 99);
  tfp->open ("code_gen.vcd");
  // initialize simulation inputs
  top->clk            = 1;
  top->rstn           = 0;
  top->tic_enable     = 0;
  top->hc_enable      = 0;
  top->prn_key_enable = 0;
  top->slew_enable    = 0;
  top->prn_key        = 0;
  top->code_slew      = 0;

  sub_top->clk        = 1;
  sub_top->rstn       = 0;
  sub_top->tic_enable = 0;
  sub_top->f_control  = 0x14F3775;
  // run simulation for 100 clock periods
  for (i=0; i<50050; i++) {
    if (i==5){
      top->rstn           = 1;
      top->prn_key_enable = 1;
      top->prn_key        = 0b0110010110;

      sub_top->rstn       = 1;
    }
    else if (i==6) {
      top->prn_key_enable = 0; // code slew test.
    }
    else if (i==7) {
      top->code_slew   = 0b00000000111; // code slew test.
      top->slew_enable = 1;             // code slew test.
      top->tic_enable  = 0;
    }
    else if (i==8) {
      top->prn_key_enable = 0;
      top->slew_enable    = 0; // code slew test.
    }
    else if (i==50008) {
      top->tic_enable = 1;
    }
    else if (i==50009) {
      top->tic_enable = 0;
    }
    else if (i==50014) {
      top->rstn = 0;
    }

    // dump variables into VCD file and toggle clock
    for (clk=0; clk<2; clk++) {
      tfp->dump ((2*i+clk)*10);

      sub_top->clk = !sub_top->clk;
      sub_top->eval ();
      top->hc_enable  = sub_top->hc_enable;
      top->tic_enable = sub_top->tic_enable;

      top->clk = !top->clk;
      top->eval ();
    }

    if (Verilated::gotFinish())  exit(0);
  }
  tfp->close();
  exit(0);
}
