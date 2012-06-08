#!/bin/sh


# cleanup
rm -rf obj_dir
rm -f  carrier_nco.vcd
rm -f carrier_nco.v
cp ../../rtl/carrier_nco.v ./


# run Verilator to translate Verilog into C++, include C++ testbench
verilator --cc --trace carrier_nco.v --exe tb_carrier_nco.cpp
# build C++ project
make -j -C obj_dir/ -f Vcarrier_nco.mk Vcarrier_nco
# run executable simulation
obj_dir/Vcarrier_nco


# view waveforms
gtkwave carrier_nco.vcd carrier_nco.sav &
