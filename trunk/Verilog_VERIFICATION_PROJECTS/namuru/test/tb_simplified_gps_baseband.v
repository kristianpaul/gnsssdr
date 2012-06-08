/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012
*/

`timescale 1ns / 1fs

///`define WB_DEBUG_MSG

module tb_simplified_gps_baseband();

reg  clk, hw_rstn;
reg  sign, mag;
reg  [31:0] wb_adr_i;
wire [31:0] wb_dat_o;
reg  [31:0] wb_dat_i;
reg  wb_stb_i;
reg  wb_cyc_i;
wire wb_ack_o;
reg  wb_we_i;
wire accum_int;

reg [3:0] sc_q;			// ouput of divide by 3 counter (used to generate clock for gps_sample);
wire gps_sample_clk;	// gps sample clock;
integer gps_sample;		//variable in wich gps signal record samples are written;

integer ie, qe, ip, qp, il, ql;
integer slew, carr_freq, code_freq;

integer status;		//Read status of correlator in this variable;
integer new_data;	//Read new_data flag of correlator in this variable;

reg flag_start_gps;


simplified_gps_baseband dut(
	.clk(clk),
	.hw_rstn(hw_rstn),
	.sign(sign),
	.mag(mag),
	.wb_adr_i(wb_adr_i),
	.wb_dat_o(wb_dat_o),
	.wb_dat_i(wb_dat_i),
	.wb_sel_i(4'hf),
	.wb_stb_i(wb_stb_i),
	.wb_cyc_i(wb_cyc_i),
	.wb_ack_o(wb_ack_o),
	.wb_we_i(wb_we_i),
	.accum_int(accum_int)
);

//Tasks that are used in this testbench:
//wait 1 clock cycle task:
task waitclock;
begin
	@(posedge clk);
	#1;
end
endtask
//wishbone write task:
task wbwrite;
input [31:0] address;
input [31:0] data;
integer i;
begin
	wb_adr_i = address;
	wb_dat_i = data;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b1;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	waitclock;
	`ifdef WB_DEBUG_MSG
	$display("WB Write: %x=%x acked in %d clocks", address, data, i);
	`endif
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask
//wishbone read task:
task wbread;
input [31:0] address;
integer i;
begin
	wb_adr_i = address;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b0;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	`ifdef WB_DEBUG_MSG
	$display("WB Read : %x=%x acked in %d clocks", address, wb_dat_o, i);
	`endif
	waitclock;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask
//set PRN task:
task set_prn;
input [31:0] data;
begin
	wbwrite(32'h20000000, data);
end
endtask
//set code slew task:
task set_code_slew;
input [31:0] data;
begin
	wbwrite(32'h2000000C, data);
end
endtask
//set code freq task:
task set_code_freq;
input [31:0] data;
begin
	wbwrite(32'h20000008, data);
end
endtask
//set carrier freq task:
task set_carr_freq;
input [31:0] data;
begin
	wbwrite(32'h20000004, data);
end
endtask
//wishbone read2 task:
task wbread2;
input [31:0] address;
output [31:0] data_read;
integer i;
begin
	wb_adr_i = address;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b0;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	`ifdef WB_DEBUG_MSG
	$display("WB Read2 : %x=%x acked in %d clocks", address, wb_dat_o, i);
	`endif
	waitclock;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
	
	data_read = wb_dat_o;
end
endtask
//read status task:
task read_status;
output [31:0] data_read;
begin
	wbread2(32'h20000380, data_read);
end
endtask
//read new data task:
task read_new_data;
output [31:0] data_read;
begin
	wbread2(32'h20000384, data_read);
end
endtask
//read ie task:
task read_ie;
output [31:0] data_read;
begin
	wbread2(32'h20000010, data_read);
end
endtask
//read qe task:
task read_qe;
output [31:0] data_read;
begin
	wbread2(32'h20000014, data_read);
end
endtask
//read ip task:
task read_ip;
output [31:0] data_read;
begin
	wbread2(32'h20000018, data_read);
end
endtask
//read qp task:
task read_qp;
output [31:0] data_read;
begin
	wbread2(32'h2000001C, data_read);
end
endtask
//read il task:
task read_il;
output [31:0] data_read;
begin
	wbread2(32'h20000020, data_read);
end
endtask
//read ql task:
task read_ql;
output [31:0] data_read;
begin
	wbread2(32'h20000024, data_read);
end
endtask

initial begin
	flag_start_gps = 1'b0;
	mag = 1'b0;
	clk = 1'b0;
	hw_rstn = 1'b0; //first system reset;
	
	$gps_file_open("e:\\GavAI\\GPS\\scilab_convert_data\\routines\\file_read\\FFF005.DAT");	//open file for reading data (gps samples reading);	
	$gpsisr_init();//init correlator control;
end

/* 48 MHz system clock */
always #10.41667 clk = ~clk;

/* 1/3 of the system clock (48/3=16 MHz) */
always @ (posedge clk)
begin
	if (!hw_rstn) sc_q <= 0;
	else
		if (sc_q == 2) sc_q <= 0;
		else sc_q <= sc_q + 1;
end
assign gps_sample_clk = (sc_q == 1)? 1:0; // accumulator sample pulse

/* reading gps signal sample from file */
always @ (posedge gps_sample_clk)
begin 
  $gps_read_sample(gps_sample);
  if(gps_sample == 1) sign = 1'b1;
  else sign = 1'b0;
end

/* interrupt reaction */
always @ (posedge accum_int)
begin
	if (hw_rstn)
	begin
		if ( flag_start_gps )
		begin
			read_status(status); waitclock;
			read_new_data(new_data); waitclock;		
			if ( (new_data==1) || (new_data==3) )
			begin
			//read correlator outputs:
///!!! HERE I READ UNSIGNED VALUES! BUT THEY MUST BE SIGNED!!! CORRECT THIS BEFORE RUNNING THE TEST!!!
				read_ie(ie); waitclock;
				read_qe(qe); waitclock;
				read_ip(ip); waitclock;
				read_qp(qp); waitclock;
				read_il(il); waitclock;
				read_ql(ql); waitclock;
				//call interrupt handler written in C:
				$gpsisr(ie, qe, ip, qp, il, ql, slew, carr_freq, code_freq);
				//update correlator blocks with new values:
				if (slew) set_code_slew(slew); waitclock;
				if (code_freq) set_code_freq(code_freq); waitclock;
				if (carr_freq) set_carr_freq(carr_freq); waitclock;
			end
		end
	end

end

always begin
	$dumpfile("simplified_gps_baseband.vcd");
	//$dumpvars(-1, dut);
	//$dumpvars(0, status);
	//$dumpvars(0, new_data);
	//$dumpvars(0, gps_sample);
	//$dumpvars(0, ie); $dumpvars(0, ip); $dumpvars(0, il);
	//$dumpvars(0, qe); $dumpvars(0, qp); $dumpvars(0, ql);
	
	
	#100 hw_rstn = 1'b1;
	//test wishbone interface;
	//write data to wishbone memory:
	wbwrite(32'h20000300, 32'h11111111); waitclock;
	wbwrite(32'h20000304, 32'h22222222); waitclock;
	wbwrite(32'h20000308, 32'h33333333); waitclock;
	wbwrite(32'h2000030C, 32'h44444444); waitclock;
	wbwrite(32'h20000310, 32'h55555555); waitclock;
	wbwrite(32'h20000314, 32'h66666666); waitclock;
	wbwrite(32'h20000318, 32'h77777777); waitclock;
	wbwrite(32'h2000031C, 32'h88888888); waitclock;
	//read data from wishbone memory:
	wbread(32'h20000340); waitclock;
	wbread(32'h20000344); waitclock;
	wbread(32'h20000348); waitclock;
	wbread(32'h2000034C); waitclock;
	wbread(32'h20000350); waitclock;
	wbread(32'h20000354); waitclock;
	wbread(32'h20000358); waitclock;
	wbread(32'h2000035C); waitclock;
	
	// Initialize time_base-module:
	//software reset:
	wbwrite(32'h200003C0, 32'h00000000); waitclock;
	//set TIC-periode:
	wbwrite(32'h200003C4, 32'h00493DFF); waitclock;
	//set Accum_int-periode:
	wbwrite(32'h200003C8, 32'h00005DBF); waitclock;
	//software reset; In order to make time_base module to simulate correctly:
	wbwrite(32'h200003C0, 32'h00000000); waitclock;
	
	
	// set code freq:
	set_code_freq(32'h015D2F1A); waitclock;
	// set PRN:
	set_prn(32'h00000360); waitclock;
	// attempt to accelerate acquisition for SVN4 in current signal record:
	set_code_slew(32'h0000060E); waitclock;
	// set carrier freq:
	set_carr_freq(32'h033A06D3); waitclock;
	
	//start gps processing:
	flag_start_gps = 1'b1;
	//and make reset to make everything rolling:
	wbwrite(32'h200003C0, 32'h00000000); waitclock;
	
	
	//#2000000 hw_rstn = 1'b0;
	#3000000000 hw_rstn = 1'b0;
	///#10000000 hw_rstn = 1'b0;
	
	$gps_file_close;	
	$finish;
end

endmodule

