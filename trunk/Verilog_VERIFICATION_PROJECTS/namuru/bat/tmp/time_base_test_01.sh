#!/bin/sh

# run Icarus verilog:
iverilog -o tb_accumulator ./../test/tb_accumulator.v ./../rtl/accumulator.v
vvp tb_accumulator > verilog.log

#View *.vcd file:
gtkwave accumulator.vcd

