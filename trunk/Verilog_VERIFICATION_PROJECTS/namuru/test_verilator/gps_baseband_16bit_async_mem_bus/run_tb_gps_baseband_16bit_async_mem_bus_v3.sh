#!/bin/sh


# cleanup
rm -rf obj_dir
rm -f  gps_baseband_16bit_async_mem_bus.vcd
rm -f gps_baseband_16bit_async_mem_bus.v
cp ../../rtl/gps_baseband_16bit_async_mem_bus.v ./
cp ../../rtl/tracking_channel.v ./
cp ../../rtl/time_base.v ./
cp ../../rtl/accumulator.v ./
cp ../../rtl/accumulator_two_inputs.v ./
cp ../../rtl/carrier_mixer.v ./
cp ../../rtl/carrier_nco.v ./
cp ../../rtl/code_gen.v ./
cp ../../rtl/code_nco.v ./
cp ../../rtl/epoch_counter.v ./
cp ../../rtl/namuro_gnss_setup.v ./

# run Verilator to translate Verilog into C++, include C++ testbench
verilator --cc --trace gps_baseband_16bit_async_mem_bus.v --exe tb_gps_baseband_16bit_async_mem_bus_v3.cpp
# build C++ project
make -j -C obj_dir/ -f Vgps_baseband_16bit_async_mem_bus.mk Vgps_baseband_16bit_async_mem_bus
# run executable simulation
obj_dir/Vgps_baseband_16bit_async_mem_bus


# view waveforms
gtkwave gps_baseband_16bit_async_mem_bus.vcd gps_baseband_16bit_async_mem_bus.sav &
