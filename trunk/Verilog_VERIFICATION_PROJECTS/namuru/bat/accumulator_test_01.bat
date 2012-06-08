iverilog -o tb_accumulator .\..\test\tb_accumulator.v .\..\rtl\accumulator.v
vvp tb_accumulator > verilog.log

gtkwave.exe accumulator.vcd