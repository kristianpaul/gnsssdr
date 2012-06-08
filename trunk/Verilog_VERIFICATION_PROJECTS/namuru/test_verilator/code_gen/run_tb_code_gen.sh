#!/bin/sh


# cleanup
rm -rf obj_dir
rm -f  code_gen.vcd
rm -f code_gen.v
cp ../../rtl/code_gen.v ./
cp ../../rtl/code_nco.v ./


# run Verilator to translate Verilog into C++, include C++ testbench
verilator --cc code_nco.v 
verilator --cc --trace code_gen.v Vcode_nco.cpp Vcode_nco__Syms.cpp --exe tb_code_gen.cpp
# build C++ project
make -j -C obj_dir/ -f Vcode_gen.mk Vcode_gen
# run executable simulation
obj_dir/Vcode_gen


# view waveforms
gtkwave code_gen.vcd code_gen.sav &
