iverilog -o tb_carrier_nco .\..\test\tb_carrier_nco.v .\..\rtl\carrier_nco.v
vvp tb_carrier_nco > verilog.log

gtkwave.exe carrier_nco.vcd