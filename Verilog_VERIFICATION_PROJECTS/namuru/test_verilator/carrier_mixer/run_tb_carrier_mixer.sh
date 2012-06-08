#!/bin/sh


# cleanup
rm -rf obj_dir
rm -f  carrier_mixer.vcd
rm -f carrier_mixer.v
cp ../../rtl/carrier_mixer.v ./


# run Verilator to translate Verilog into C++, include C++ testbench
verilator --cc --trace carrier_mixer.v --exe tb_carrier_mixer.cpp
# build C++ project
make -j -C obj_dir/ -f Vcarrier_mixer.mk Vcarrier_mixer
# run executable simulation
obj_dir/Vcarrier_mixer


# view waveforms
gtkwave carrier_mixer.vcd carrier_mixer.sav &
