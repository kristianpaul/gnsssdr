/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012

Data1.txt is generated in this test. It contains signal record for
farther analysis in scilab or any other tool. File 'sci_carrier_nco.sce'
is used for analyzing. It reads signal record from the file 'Data1.txt'
and takes its FFT. Then frequency bin is compared with the expected one manually.
*/

#include <iostream>
#include <fstream>
#include "Vcarrier_nco.h"
#include "verilated.h"
#include "verilated_vcd_c.h"


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  // output test data to file;
  int i_carr, q_carr;
  ofstream fout1;
  ofstream fout2;
  fout1.open("i_carr.dat");
  fout2.open("q_carr.dat");    

  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vcarrier_nco* top = new Vcarrier_nco;
  // init trace dump
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace (tfp, 99);
  tfp->open ("carrier_nco.vcd");
  // initialize simulation inputs
  top->clk        = 1;
  top->rstn       = 0;
  top->tic_enable = 0;
  // run simulation for 100 clock periods
  for (i=0; i<25100; i++) {
    if (i==5){
      top->rstn      = 1;          // stop system reset;
      top->f_control = 0x0318FC50; //2.42MHz for 50 MHz system clock;
    }
    else if (i==25005) {
      top->tic_enable = 1;
    }
    else if (i==25010) {
      top->rstn = 0;
    }

    i_carr = ((top->i_sign && 1)<<1) + (top->i_mag && 1);
    q_carr = ((top->q_sign && 1)<<1) + (top->q_mag && 1);
    fout1 << i_carr << "\n";
    fout2 << q_carr << "\n";

    // dump variables into VCD file and toggle clock
    for (clk=0; clk<2; clk++) {
      tfp->dump ((2*i+clk)*10);
      top->clk = !top->clk;
      top->eval ();
    }

    if (Verilated::gotFinish())  exit(0);
  }
  tfp->close();

  fout1.close();
  fout2.close();

  exit(0);
}
