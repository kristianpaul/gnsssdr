#!/bin/sh

# run Icarus verilog:
iverilog -o tb_carrier_mixer ./../test/tb_carrier_mixer.v ./../rtl/carrier_mixer.v
vvp tb_carrier_mixer > verilog.log

#View *.vcd file:
gtkwave carrier_mixer.vcd

