iverilog -o tb_carrier_mixer .\..\test\tb_carrier_mixer.v .\..\rtl\carrier_mixer.v
vvp tb_carrier_mixer > verilog.log

gtkwave.exe carrier_mixer.vcd