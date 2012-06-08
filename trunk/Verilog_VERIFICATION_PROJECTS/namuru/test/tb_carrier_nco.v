/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012

Data1.txt is generated in this test. It contains signal record for
farther analysis in scilab or any other tool. File 'sci_carrier_nco.sce'
is used for analyzing. It reads signal record from the file 'Data1.txt'
and takes its FFT. Then frequency bin is compared with the expected one manually.
*/

`timescale 1ns / 1ps

module tb_carrier_nco();


reg clk, rstn, tic_enable;
reg [28:0] f_control;

wire [31:0] carrier_val;
wire i_sign, i_mag;
wire q_sign, q_mag;

//some additional signals used in verification in scilab (plotting signal spectrum).
wire [1:0] i_carr;
wire [1:0] q_carr;
integer dat1; //Write signal in this file;


carrier_nco dut(
	.clk(clk),
	.rstn(rstn),
	.tic_enable(tic_enable),
	.f_control(f_control),
	.carrier_val(carrier_val),
	.i_sign(i_sign),
	.i_mag(i_mag),
	.q_sign(q_sign),
	.q_mag(q_mag)
);


/* 50 MHz system clock */
initial begin
	clk = 1'b0;
	rstn = 1'b0; //first system reset;
	dat1 = $fopen("Data1.txt"); //Open file to write data in.
end

always #10 clk = ~clk;

assign i_carr = {i_sign, i_mag}; //combine sign and magnitude;
assign q_carr = {q_sign, q_mag}; //combine sign and magnitude;

always @ (posedge clk)
	if (i_carr!==2'bxx) //exclude 'x' values - otherwise scilab will meet problems with converting 'x' to number.
		$fdisplay(dat1, "%d", i_carr); //Write signal in file for later analyzing in scilab;

always begin
	$dumpfile("carrier_nco.vcd");
	$dumpvars(-1, dut);

	#100 rstn = 1'b1; // stop system reset;
	f_control = 29'h318FC50; //2.42MHz for 50 MHz system clock;
	
	#500000 tic_enable = 1'b1;
	
	#100 rstn = 1'b0;
	
	$fclose(dat1);
	$finish;
end

endmodule

