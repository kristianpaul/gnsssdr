/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012
Just a simple test of code generator.
*/

`timescale 1ns / 1ps

module tb_code_gen();

reg clk, rstn, tic_enable;
wire hc_enable;
reg prn_key_enable;
reg slew_enable;
reg [9:0] prn_key;
reg [10:0] code_slew;

wire dump_enable;
wire [10:0] code_phase;
wire early, prompt, late;


code_gen dut(
	.clk(clk),
	.rstn(rstn),
	.tic_enable(tic_enable),
	.hc_enable(hc_enable),
	.prn_key_enable(prn_key_enable),
	.prn_key(prn_key),
	.code_slew(code_slew),
	.slew_enable(slew_enable),
	.dump_enable(dump_enable),
	.code_phase(code_phase),
	.early(early),
	.prompt(prompt),
	.late(late)
);

reg [27:0] f_control;
wire [9:0] code_val;

//create code_nco in order to generate clock for code-generator.
code_nco codenco(
	.clk(clk),
	.rstn(rstn),
	.tic_enable(tic_enable),
	.f_control(f_control),
	.hc_enable(hc_enable),
	.code_nco_phase(code_val)
);


/* 50 MHz system clock */
initial begin
	clk = 1'b0;
	rstn = 1'b0;
	f_control = 28'hD14F3776; //set code_nco frequency=2.046MHz for 50MHz system clock.
end

always #10 clk = ~clk;

always begin
	$dumpfile("code_gen.vcd");
	$dumpvars(-1, dut);

	#100 rstn = 1'b1;
	prn_key_enable = 1'b1;
	prn_key = 10'b0110010110;
		
	#20 prn_key_enable = 1'b0; // code slew test.
		
	#20	code_slew = 11'b00000000111; // code slew test.
	slew_enable = 1'b1; // code slew test.
	tic_enable = 1'b0;
		
	#20 prn_key_enable = 1'b0;
	slew_enable = 1'b0; // code slew test.
		
	#1000000 tic_enable = 1'b1;
	
	#20 tic_enable = 1'b0;
		

	#100 rstn = 1'b0;
	
	$finish;
end

endmodule

