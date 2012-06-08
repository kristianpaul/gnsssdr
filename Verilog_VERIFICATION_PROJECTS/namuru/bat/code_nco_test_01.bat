iverilog -o tb_code_nco .\..\test\tb_code_nco.v .\..\rtl\code_nco.v
vvp tb_code_nco > verilog.log

gtkwave.exe code_nco.vcd