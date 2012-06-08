/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012

Just a simple experiment of writing testbenche for accumulator.v. It's only example of
testbench. Further research must be done to check accumulator.v correctness!

In this test all combinations of if_sign, if_mag and 
carrier_sign, carrier_mag are checked. Result must be checked manually.
*/

`timescale 1ns / 1ps

module tb_carrier_mixer();

reg if_sign;
reg if_mag;
reg carrier_sign;
reg carrier_mag;

wire mix_sign;
wire mix_mag;

carrier_mixer dut(
	.if_sign(if_sign),
	.if_mag(if_mag),
	.carrier_sign(carrier_sign),
	.carrier_mag(carrier_mag),
	.mix_sign(mix_sign),
	.mix_mag(mix_mag)
);

always begin
	$dumpfile("carrier_mixer.vcd");
	$dumpvars(-1, dut);

	#20 if_sign = 1'b0; if_mag = 1'b0; //if=-1;
	carrier_sign = 1'b0; carrier_mag = 1'b0; //carrier=-1;
	
	#20 if_sign = 1'b0; if_mag = 1'b1; //if=-3;
	carrier_sign = 1'b0; carrier_mag = 1'b0; //carrier=-1;
	
	#20 if_sign = 1'b1; if_mag = 1'b0; //if=+1;
	carrier_sign = 1'b0; carrier_sign = 1'b0; //carrier=-1;
	
	#20 if_sign = 1'b1; if_mag = 1'b1; //if=+3;
	carrier_sign = 1'b0; carrier_mag = 1'b0; //carrier=-1;
	
	
	
	#20 if_sign = 1'b0; if_mag = 1'b0; //if=-1;
	carrier_sign = 1'b0; carrier_mag = 1'b1; //carrier=-2;
	
	#20 if_sign = 1'b0; if_mag = 1'b1; //if=-3;
	carrier_sign = 1'b0; carrier_mag = 1'b1; //carrier=-2;
	
	#20 if_sign = 1'b1; if_mag = 1'b0; //if=+1;
	carrier_sign = 1'b0; carrier_mag = 1'b1; //carrier=-2;
	
	#20 if_sign = 1'b1; if_mag = 1'b1; //if=+3;
	carrier_sign = 1'b0; carrier_mag = 1'b1; //carrier=-2;
	
	
	
	#20 if_sign = 1'b0; if_mag = 1'b0; //if=-1;
	carrier_sign = 1'b1; carrier_mag = 1'b0; //carrier=+1;
	
	#20 if_sign = 1'b0; if_mag = 1'b1; //if=-3;
	carrier_sign = 1'b1; carrier_mag = 1'b0; //carrier=+1;
	
	#20 if_sign = 1'b1; if_mag = 1'b0; //if=+1;
	carrier_sign = 1'b1; carrier_mag = 1'b0; //carrier=+1;

	#20 if_sign = 1'b1; if_mag = 1'b1; //if=+3;
	carrier_sign = 1'b1; carrier_mag = 1'b0; //carrier=+1;

	
	
	#20 if_sign = 1'b0; if_mag = 1'b0; //if=-1;
	carrier_sign = 1'b1; carrier_mag = 1'b1; //carrier=+2;	
	
	#20 if_sign = 1'b0; if_mag = 1'b1; //if=-3;
	carrier_sign = 1'b1; carrier_mag = 1'b1; //carrier=+2;
	
	#20 if_sign = 1'b1; if_mag = 1'b0; //if=+1;
	carrier_sign = 1'b1; carrier_mag = 1'b1; //carrier=+2;

	#20 if_sign = 1'b1; if_mag = 1'b1; //if=+3;
	carrier_sign = 1'b1; carrier_mag = 1'b1; //carrier=+2;
	
	#20 if_sign = 1'b0; if_mag = 1'b0;
	carrier_sign = 1'b0; carrier_mag = 1'b0;
	
	$finish;
end

endmodule

