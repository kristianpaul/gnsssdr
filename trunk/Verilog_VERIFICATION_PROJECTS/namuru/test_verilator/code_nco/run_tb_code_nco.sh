#!/bin/sh


# cleanup
rm -rf obj_dir
rm -f  code_nco.vcd
rm -f code_nco.v
cp ../../rtl/code_nco.v ./


# run Verilator to translate Verilog into C++, include C++ testbench
verilator --cc --trace code_nco.v --exe tb_code_nco.cpp
# build C++ project
make -j -C obj_dir/ -f Vcode_nco.mk Vcode_nco
# run executable simulation
obj_dir/Vcode_nco


# view waveforms
gtkwave code_nco.vcd code_nco.sav &
