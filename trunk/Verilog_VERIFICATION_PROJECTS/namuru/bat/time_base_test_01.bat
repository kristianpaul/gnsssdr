iverilog -o tb_time_base .\..\test\tb_time_base.v .\..\rtl\time_base.v
vvp tb_time_base > verilog.log

gtkwave.exe time_base.vcd