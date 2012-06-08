/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012

Just a simple experiment of writing testbenche for accumulator.v. It's only example of
testbench. Further research must be done to check accumulator.v correctness!
*/

`timescale 1ns / 1ps

module tb_accumulator();

reg clk;
reg rstn;
reg sample_enable;
reg code;
reg carrier_mix_sign;
reg [2:0] carrier_mix_mag;
reg dump_enable;

wire [15:0] accumulation;

accumulator dut(
	.clk(clk),
	.rstn(rstn),

	.sample_enable(sample_enable),
	.code(code),
	.carrier_mix_sign(carrier_mix_sign),
	.carrier_mix_mag(carrier_mix_mag),
	.dump_enable(dump_enable),
	.accumulation(accumulation)
);


/* 100MHz system clock */
initial begin
	clk = 1'b0;
	sample_enable = 1'b0;
end

always #12.5 clk = ~clk;
always #25 sample_enable = ~sample_enable;

always begin
	$dumpfile("accumulator.vcd");
	$dumpvars(-1, dut);

	rstn = 1'b0;

	#100 rstn = 1'b1;
	dump_enable = 1'b0;
	code = 1'b1;
	carrier_mix_sign = 1'b1;
	carrier_mix_mag = 3'd3;
	
	#400 carrier_mix_mag = 3'd1;
	
	#200 carrier_mix_sign = 1'b0;
	carrier_mix_mag = 3'd2;
	
	#500 dump_enable = 1'b1;
	
	#50 dump_enable = 1'b0;
	
	
	$finish;
end

endmodule

