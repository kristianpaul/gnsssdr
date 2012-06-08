iverilog-vpi .\..\vpi\namuru_vpi.c
iverilog -o tb_simplified_gps_baseband .\..\test\tb_simplified_gps_baseband.v .\..\rtl\simplified_gps_baseband.v .\..\rtl\time_base.v .\..\rtl\tracking_channel.v .\..\rtl\carrier_mixer.v .\..\rtl\carrier_nco.v .\..\rtl\code_nco.v .\..\rtl\code_gen.v .\..\rtl\epoch_counter.v .\..\rtl\accumulator.v .\..\vpi\namuru_vpi.vvp
vvp -M .\..\vpi -m namuru_vpi tb_simplified_gps_baseband > verilog.log

gtkwave.exe simplified_gps_baseband.vcd