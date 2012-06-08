/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012
After the test is made gtkwave window opens. hc_enable
periode (or frequency) must be manually checked with the expected value.
*/

`timescale 1ns / 1ps

module tb_code_nco();

reg clk, rstn, tic_enable;
reg [27:0] f_control;

wire hc_enable;
wire [9:0] code_nco_phase;


code_nco dut(
	.clk(clk),
	.rstn(rstn),
	.tic_enable(tic_enable),
	.f_control(f_control),
	.hc_enable(hc_enable),
	.code_nco_phase(code_nco_phase)
);


/* 50 MHz system clock */
initial begin
	clk = 1'b0;
end

always #10 clk = ~clk;

always begin
	$dumpfile("code_nco.vcd");
	$dumpvars(-1, dut);

	rstn = 1'b0;

	#100 rstn = 1'b1;
	f_control = 28'hD14F3776; //2.046 hc clock for 50 MHz system clock;
	
	#1000000 tic_enable = 1'b1;
	
	#100 rstn = 1'b0;
	
	$finish;
end

endmodule

