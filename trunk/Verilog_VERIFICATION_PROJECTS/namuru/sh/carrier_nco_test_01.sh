#!/bin/sh

# run Icarus verilog:
iverilog -o tb_carrier_nco ./../test/tb_carrier_nco.v ./../rtl/carrier_nco.v
vvp tb_carrier_nco > verilog.log

#View *.vcd file:
gtkwave carrier_nco.vcd

