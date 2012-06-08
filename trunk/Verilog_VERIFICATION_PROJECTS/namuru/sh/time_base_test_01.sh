#!/bin/sh

# run Icarus verilog:
iverilog -o tb_time_base ./../test/tb_time_base.v ./../rtl/time_base.v
vvp tb_time_base > verilog.log

#View *.vcd file:
gtkwave time_base.vcd

