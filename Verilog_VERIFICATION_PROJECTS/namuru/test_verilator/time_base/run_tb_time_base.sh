#!/bin/sh


# cleanup
rm -rf obj_dir
rm -f  time_base.vcd
rm -f time_base.v
cp ../../rtl/time_base.v ./


# run Verilator to translate Verilog into C++, include C++ testbench
verilator --cc --trace time_base.v --exe tb_time_base.cpp
# build C++ project
make -j -C obj_dir/ -f Vtime_base.mk Vtime_base
# run executable simulation
obj_dir/Vtime_base


# view waveforms
gtkwave time_base.vcd time_base.sav &
