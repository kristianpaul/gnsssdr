#!/bin/sh


# cleanup
rm -rf obj_dir
rm -f  simplified_gps_baseband.vcd
rm -f simplified_gps_baseband.v
cp ../../rtl/simplified_gps_baseband.v ./
cp ../../rtl/tracking_channel.v ./
cp ../../rtl/time_base.v ./
cp ../../rtl/accumulator.v ./
cp ../../rtl/carrier_mixer.v ./
cp ../../rtl/carrier_nco.v ./
cp ../../rtl/code_gen.v ./
cp ../../rtl/code_nco.v ./
cp ../../rtl/epoch_counter.v ./

# run Verilator to translate Verilog into C++, include C++ testbench
verilator --cc --trace simplified_gps_baseband.v --exe tb_simplified_gps_baseband.cpp
# build C++ project
make -j -C obj_dir/ -f Vsimplified_gps_baseband.mk Vsimplified_gps_baseband
# run executable simulation
obj_dir/Vsimplified_gps_baseband


# view waveforms
gtkwave simplified_gps_baseband.vcd simplified_gps_baseband.sav &
