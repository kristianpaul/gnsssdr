#!/bin/sh


# cleanup
rm -rf obj_dir
rm -f  accumulator.vcd
rm -f accumulator.v
cp ../../rtl/accumulator.v ./


# run Verilator to translate Verilog into C++, include C++ testbench
verilator --cc --trace accumulator.v --exe tb_accumulator.cpp
# build C++ project
make -j -C obj_dir/ -f Vaccumulator.mk Vaccumulator
# run executable simulation
obj_dir/Vaccumulator


# view waveforms
gtkwave accumulator.vcd accumulator.sav &
