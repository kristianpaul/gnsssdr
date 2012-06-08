/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012
*/

`timescale 1ns / 1fs

module tb_time_base();

reg clk, rstn;
reg [23:0] tic_divide;
reg [23:0] accum_divide;

wire pre_tic_enable;
wire tic_enable;
wire accum_enable;
wire accum_sample_enable;
wire [23:0] tic_count;
wire [23:0] accum_count;

time_base dut(
	.clk(clk),
	.rstn(rstn),
	.tic_divide(tic_divide),
	.accum_divide(accum_divide),
	.pre_tic_enable(pre_tic_enable),
	.tic_enable(tic_enable),
	.accum_enable(accum_enable),
	.accum_sample_enable(accum_sample_enable),
	.tic_count(tic_count),
	.accum_count(accum_count)
);


/* 50 MHz system clock */
initial begin
	clk = 1'b0;
	rstn = 1'b0;
end

always #10.41667 clk = ~clk;

always begin
	$dumpfile("time_base.vcd");
	$dumpvars(-1, dut);

	#100 rstn = 1'b1;
	
	tic_divide   = 24'd255;
	accum_divide = 24'd511;
	
	#100000 rstn = 1'b0;
	
	$finish;
end

endmodule

