#!/bin/sh

# run Icarus verilog:
iverilog -o tb_code_gen ./../test/tb_code_gen.v ./../rtl/code_gen.v ./../rtl/code_nco.v
vvp tb_code_gen > verilog.log

#View *.vcd file:
gtkwave code_gen.vcd

