//                              -*- Mode: Verilog -*-
// Filename        : gps_baseband.v
// Description     : top level, includes address decoder and X tracking channels
// Author          : Peter Mumford UNSW 2005

// ----------------------------------------------------------------------------------------
// fix log
// ----------------------------------------------------------------------------------------
// 2/3/07 : Peter Mumford
// Fixed a problem when a new data read coincides or imediately
// follows a dump pulse. In this case the new data flag for that channel is lost.
// The fix involved capturing the dump state of all channels on a read of the
// new data register and using it as a mask for the new data flags.
// The following registers accomplish a two clock cycle wide mask function.
//   reg [11:0] dump_mask; // mask a channel that has a dump aligned with the new data read
//   reg [11:0] dump_mask_2; // mask for two clock cycles
// ----------------------------------------------------------------------------------------

/* This module connects to the Avalon bus

 address map
 block       address offset
 -------------------------
 chan 0        00-0F
 chan 1        10-1F
 chan 2        20-2F
 chan 3        30-3F
 chan 4        40-4F
 chan 5        50-5F
 chan 6        60-6F
 chan 7        70-7F
 chan 8        80-8F
 chan 9        90-9F
 chan 10       A0-AF
 chan 11       B0-BF
 spare         C0-CF
 spare         D0-DF
 status        E0-EF
 control       F0-FF
 
 channel     address offset
 -------------------------
 prn_key      0    write
 carrier_nco  1    write
 code_nco     2    write
 code_slew    3    write
 I_early      4    read
 Q_early      5    read
 I_prompt     6    read
 Q_prompt     7    read
 I_late       8    read
 Q_late       9    read
 carrier_val  A    read
 code_val     B    read
 epoch        C    read
 epoch_check  D    read
 spare       E-F
 
 status     address offset
 -------------------------
 status       0    read
 new_data     1    read
 tic_count    2    read
 accum_count  3    read
 spare       4-F
 
 control    address offset
 -------------------------
 reset           0
 prog_tic        1   write
 prog_accum_int  2   write
 spare          3-F
 
 */

module gps_baseband_16bit_async_mem_bus (clk, hw_rstn,
                                         //input from front-end:
                                         sign, mag,
                                         //external interface:
                                         csn_a, wen_a, oen_a,//[Art]
                                         address, data, //[Art]
                                         //interrupt for mcu:
                                         accum_int,
                                         //test points for FPGA:
                                         test_point_01, test_point_02, test_point_03,
                                         test_point_04, test_point_05
		                        );

  input clk, hw_rstn;
  input sign, mag; // raw data in from RF front end
  input csn_a, wen_a, oen_a;
  input [9:0] address;
  inout [15:0] data;
  output accum_int; // interrupt pulse to tell FW to collect accumulation data, cleared on STATUS read
  output test_point_01, test_point_02, test_point_03, test_point_04, test_point_05;
  
  reg [15:0] data_out;

  wire s_clk;
  wire accum_enable_s;
  wire pre_tic_enable, tic_enable, accum_sample_enable;

  wire [23:0] tic_count;
  wire [23:0] accum_count;

  wire rstn; // software generated reset  

  // channel 0 registers
  reg [9:0]  ch0_prn_key;
  reg [15:0] ch0_carr_nco_low;//[Art]
  reg [28:0] ch0_carr_nco;
  reg [15:0] ch0_code_nco_low;//[Art]
  reg [27:0] ch0_code_nco;
  reg [10:0] ch0_code_slew;
  reg [10:0] ch0_epoch_load;
  reg ch0_prn_key_enable, ch0_slew_enable, ch0_epoch_enable;
  wire ch0_dump;
  wire [15:0] ch0_i_early, ch0_q_early, ch0_i_prompt, ch0_q_prompt, ch0_i_late, ch0_q_late;
  wire [31:0] ch0_carrier_val;
  wire [20:0] ch0_code_val;
  wire [10:0] ch0_epoch, ch0_epoch_check;
      
   // channel 1 registers
  reg [9:0]  ch1_prn_key;
  reg [15:0] ch1_carr_nco_low;//[Art]
  reg [28:0] ch1_carr_nco;
  reg [15:0] ch1_code_nco_low;//[Art]
  reg [27:0] ch1_code_nco;
  reg [10:0] ch1_code_slew;
  reg [10:0] ch1_epoch_load;
  reg ch1_prn_key_enable, ch1_slew_enable, ch1_epoch_enable;
  wire ch1_dump;
  wire [15:0] ch1_i_early, ch1_q_early, ch1_i_prompt, ch1_q_prompt, ch1_i_late, ch1_q_late;
  wire [31:0] ch1_carrier_val;
  wire [20:0] ch1_code_val;
  wire [10:0] ch1_epoch, ch1_epoch_check;

  // channel 2 registers
  reg [9:0]  ch2_prn_key;
  reg [15:0] ch2_carr_nco_low;//[Art]
  reg [28:0] ch2_carr_nco;
  reg [15:0] ch2_code_nco_low;//[Art]
  reg [27:0] ch2_code_nco;
  reg [10:0] ch2_code_slew;
  reg [10:0] ch2_epoch_load;
  reg ch2_prn_key_enable, ch2_slew_enable, ch2_epoch_enable;
  wire ch2_dump;
  wire [15:0] ch2_i_early, ch2_q_early, ch2_i_prompt, ch2_q_prompt, ch2_i_late, ch2_q_late;
  wire [31:0] ch2_carrier_val;
  wire [20:0] ch2_code_val;
  wire [10:0] ch2_epoch, ch2_epoch_check;

  // channel 3 registers
  reg [9:0]  ch3_prn_key;
  reg [15:0] ch3_carr_nco_low;//[Art]
  reg [28:0] ch3_carr_nco;
  reg [15:0] ch3_code_nco_low;//[Art]
  reg [27:0] ch3_code_nco;
  reg [10:0] ch3_code_slew;
  reg [10:0] ch3_epoch_load;
  reg ch3_prn_key_enable, ch3_slew_enable, ch3_epoch_enable;
  wire ch3_dump;
  wire [15:0] ch3_i_early, ch3_q_early, ch3_i_prompt, ch3_q_prompt, ch3_i_late, ch3_q_late;
  wire [31:0] ch3_carrier_val;
  wire [20:0] ch3_code_val;
  wire [10:0] ch3_epoch, ch3_epoch_check;

  // channel 4 registers
  reg [9:0]  ch4_prn_key;
  reg [15:0] ch4_carr_nco_low;//[Art]
  reg [28:0] ch4_carr_nco;
  reg [15:0] ch4_code_nco_low;//[Art]
  reg [27:0] ch4_code_nco;
  reg [10:0] ch4_code_slew;
  reg [10:0] ch4_epoch_load;
  reg ch4_prn_key_enable, ch4_slew_enable, ch4_epoch_enable;
  wire ch4_dump;
  wire [15:0] ch4_i_early, ch4_q_early, ch4_i_prompt, ch4_q_prompt, ch4_i_late, ch4_q_late;
  wire [31:0] ch4_carrier_val;
  wire [20:0] ch4_code_val;
  wire [10:0] ch4_epoch, ch4_epoch_check;

  // channel 5 registers
  reg [9:0]  ch5_prn_key;
  reg [15:0] ch5_carr_nco_low;//[Art]
  reg [28:0] ch5_carr_nco;
  reg [15:0] ch5_code_nco_low;//[Art]
  reg [27:0] ch5_code_nco;
  reg [10:0] ch5_code_slew;
  reg [10:0] ch5_epoch_load;
  reg ch5_prn_key_enable, ch5_slew_enable, ch5_epoch_enable;
  wire ch5_dump;
  wire [15:0] ch5_i_early, ch5_q_early, ch5_i_prompt, ch5_q_prompt, ch5_i_late, ch5_q_late;
  wire [31:0] ch5_carrier_val;
  wire [20:0] ch5_code_val;
  wire [10:0] ch5_epoch, ch5_epoch_check;

  // channel 6 registers
  reg [9:0]  ch6_prn_key;
  reg [15:0] ch6_carr_nco_low;//[Art]
  reg [28:0] ch6_carr_nco;
  reg [15:0] ch6_code_nco_low;//[Art]
  reg [27:0] ch6_code_nco;
  reg [10:0] ch6_code_slew;
  reg [10:0] ch6_epoch_load;
  reg ch6_prn_key_enable, ch6_slew_enable, ch6_epoch_enable;
  wire ch6_dump;
  wire [15:0] ch6_i_early, ch6_q_early, ch6_i_prompt, ch6_q_prompt, ch6_i_late, ch6_q_late;
  wire [31:0] ch6_carrier_val;
  wire [20:0] ch6_code_val;
  wire [10:0] ch6_epoch, ch6_epoch_check;

  // channel 7 registers
  reg [9:0]  ch7_prn_key;
  reg [15:0] ch7_carr_nco_low;//[Art]
  reg [28:0] ch7_carr_nco;
  reg [15:0] ch7_code_nco_low;//[Art]
  reg [27:0] ch7_code_nco;
  reg [10:0] ch7_code_slew;
  reg [10:0] ch7_epoch_load;
  reg ch7_prn_key_enable, ch7_slew_enable, ch7_epoch_enable;
  wire ch7_dump;
  wire [15:0] ch7_i_early, ch7_q_early, ch7_i_prompt, ch7_q_prompt, ch7_i_late, ch7_q_late;
  wire [31:0] ch7_carrier_val;
  wire [20:0] ch7_code_val;
  wire [10:0] ch7_epoch, ch7_epoch_check;

  // channel 8 registers
  reg [9:0]  ch8_prn_key;
  reg [15:0] ch8_carr_nco_low;//[Art]
  reg [28:0] ch8_carr_nco;
  reg [15:0] ch8_code_nco_low;//[Art]
  reg [27:0] ch8_code_nco;
  reg [10:0] ch8_code_slew;
  reg [10:0] ch8_epoch_load;
  reg ch8_prn_key_enable, ch8_slew_enable, ch8_epoch_enable;
  wire ch8_dump;
  wire [15:0] ch8_i_early, ch8_q_early, ch8_i_prompt, ch8_q_prompt, ch8_i_late, ch8_q_late;
  wire [31:0] ch8_carrier_val;
  wire [20:0] ch8_code_val;
  wire [10:0] ch8_epoch, ch8_epoch_check;

  // channel 9 registers
  reg [9:0]  ch9_prn_key;
  reg [15:0] ch9_carr_nco_low;//[Art]
  reg [28:0] ch9_carr_nco;
  reg [15:0] ch9_code_nco_low;//[Art]
  reg [27:0] ch9_code_nco;
  reg [10:0] ch9_code_slew;
  reg [10:0] ch9_epoch_load;
  reg ch9_prn_key_enable, ch9_slew_enable, ch9_epoch_enable;
  wire ch9_dump;
  wire [15:0] ch9_i_early, ch9_q_early, ch9_i_prompt, ch9_q_prompt, ch9_i_late, ch9_q_late;
  wire [31:0] ch9_carrier_val;
  wire [20:0] ch9_code_val;
  wire [10:0] ch9_epoch, ch9_epoch_check;

  // channel 10 registers
  reg [9:0]  ch10_prn_key;
  reg [15:0] ch10_carr_nco_low;//[Art]
  reg [28:0] ch10_carr_nco;
  reg [15:0] ch10_code_nco_low;//[Art]
  reg [27:0] ch10_code_nco;
  reg [10:0] ch10_code_slew;
  reg [10:0] ch10_epoch_load;
  reg ch10_prn_key_enable, ch10_slew_enable, ch10_epoch_enable;
  wire ch10_dump;
  wire [15:0] ch10_i_early, ch10_q_early, ch10_i_prompt, ch10_q_prompt, ch10_i_late, ch10_q_late;
  wire [31:0] ch10_carrier_val;
  wire [20:0] ch10_code_val;
  wire [10:0] ch10_epoch, ch10_epoch_check;

  // channel 11 registers
  reg [9:0]  ch11_prn_key;
  reg [15:0] ch11_carr_nco_low;//[Art]
  reg [28:0] ch11_carr_nco;
  reg [15:0] ch11_code_nco_low;//[Art]
  reg [27:0] ch11_code_nco;
  reg [10:0] ch11_code_slew;
  reg [10:0] ch11_epoch_load;
  reg ch11_prn_key_enable, ch11_slew_enable, ch11_epoch_enable;
  wire ch11_dump;
  wire [15:0] ch11_i_early, ch11_q_early, ch11_i_prompt, ch11_q_prompt, ch11_i_late, ch11_q_late;
  wire [31:0] ch11_carrier_val;
  wire [20:0] ch11_code_val;
  wire [10:0] ch11_epoch, ch11_epoch_check;
  
  // status registers
  reg [1:0] status;      // TIC = bit 0, ACCUM_INT = bit 1, cleared on read
  reg [1:0] status_miss; //[Art] //The same as status but used during bus-read process instead of status.
  reg [1:0] status_old;  //[Art] //Used to clear status bits that are read during bus-read process;

  reg [11:0] new_data;      // chan0 = bit 0, chan1 = bit 1 etc, cleared on read.
  reg [11:0] new_data_miss; //[Art] //The same as new_data but used during bus-read process instead of new_data.
  reg [11:0] new_data_old;  //[Art] //Used to clear new_data bits that are read during bus-read process.

  // control registers
  reg [23:0] prog_tic;
  reg [23:0] prog_accum_int;

  //memory for testing wishbone-interface:
  reg [31:0] test_memory [0:7];	//eight 32-bit-wide words;

  //async memory flip-flops to prevent metastability:
  reg csn_1, csn;
  reg wen_1, wen;
  reg oen_1, oen;

  // connect up time base
  time_base tb (.clk(clk), .rstn(rstn),
                .tic_divide(prog_tic),
                .accum_divide(prog_accum_int),
                .pre_tic_enable(pre_tic_enable),
                .tic_enable(tic_enable),
                .accum_enable(accum_enable_s),
                .accum_sample_enable(accum_sample_enable),
                .tic_count(tic_count),
                .accum_count(accum_count)
               );
   
  assign sample_clk = s_clk;
   
  // connect up tracking channels
  tracking_channel tc0 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch0_carr_nco),
                        .code_nco_fc(ch0_code_nco),
                        .prn_key(ch0_prn_key),
                        .prn_key_enable(ch0_prn_key_enable),
                        .code_slew(ch0_code_slew),
                        .slew_enable(ch0_slew_enable),
                        .epoch_enable(ch0_epoch_enable),
                        .dump(ch0_dump),
                        .i_early(ch0_i_early),
                        .q_early(ch0_q_early),
                        .i_prompt(ch0_i_prompt),
                        .q_prompt(ch0_q_prompt),
                        .i_late(ch0_i_late),
                        .q_late(ch0_q_late),
                        .carrier_val(ch0_carrier_val),
                        .code_val(ch0_code_val),
                        .epoch_load(ch0_epoch_load),
                        .epoch(ch0_epoch),
                        .epoch_check(ch0_epoch_check));

/*  tracking_channel tc1 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch1_carr_nco),
                        .code_nco_fc(ch1_code_nco),
                        .prn_key(ch1_prn_key),
                        .prn_key_enable(ch1_prn_key_enable),
                        .code_slew(ch1_code_slew),
                        .slew_enable(ch1_slew_enable),
                        .epoch_enable(ch1_epoch_enable),
                        .dump(ch1_dump),
                        .i_early(ch1_i_early),
                        .q_early(ch1_q_early),
                        .i_prompt(ch1_i_prompt),
                        .q_prompt(ch1_q_prompt),
                        .i_late(ch1_i_late),
                        .q_late(ch1_q_late),
                        .carrier_val(ch1_carrier_val),
                        .code_val(ch1_code_val),
                        .epoch_load(ch1_epoch_load),
                        .epoch(ch1_epoch),
                        .epoch_check(ch1_epoch_check));      
  
  tracking_channel tc2 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch2_carr_nco),
                        .code_nco_fc(ch2_code_nco),
                        .prn_key(ch2_prn_key),
                        .prn_key_enable(ch2_prn_key_enable),
                        .code_slew(ch2_code_slew),
                        .slew_enable(ch2_slew_enable),
                        .epoch_enable(ch2_epoch_enable),
                        .dump(ch2_dump),
                        .i_early(ch2_i_early),
                        .q_early(ch2_q_early),
                        .i_prompt(ch2_i_prompt),
                        .q_prompt(ch2_q_prompt),
                        .i_late(ch2_i_late),
                        .q_late(ch2_q_late),
                        .carrier_val(ch2_carrier_val),
                        .code_val(ch2_code_val),
                        .epoch_load(ch2_epoch_load),
                        .epoch(ch2_epoch),
                        .epoch_check(ch2_epoch_check));

  tracking_channel tc3 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch3_carr_nco),
                        .code_nco_fc(ch3_code_nco),
                        .prn_key(ch3_prn_key),
                        .prn_key_enable(ch3_prn_key_enable),
                        .code_slew(ch3_code_slew),
                        .slew_enable(ch3_slew_enable),
                        .epoch_enable(ch3_epoch_enable),
                        .dump(ch3_dump),
                        .i_early(ch3_i_early),
                        .q_early(ch3_q_early),
                        .i_prompt(ch3_i_prompt),
                        .q_prompt(ch3_q_prompt),
                        .i_late(ch3_i_late),
                        .q_late(ch3_q_late),
                        .carrier_val(ch3_carrier_val),
                        .code_val(ch3_code_val),
                        .epoch_load(ch3_epoch_load),
                        .epoch(ch3_epoch),
                        .epoch_check(ch3_epoch_check));

  tracking_channel tc4 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch4_carr_nco),
                        .code_nco_fc(ch4_code_nco),
                        .prn_key(ch4_prn_key),
                        .prn_key_enable(ch4_prn_key_enable),
                        .code_slew(ch4_code_slew),
                        .slew_enable(ch4_slew_enable),
                        .epoch_enable(ch4_epoch_enable),
                        .dump(ch4_dump),
                        .i_early(ch4_i_early),
                        .q_early(ch4_q_early),
                        .i_prompt(ch4_i_prompt),
                        .q_prompt(ch4_q_prompt),
                        .i_late(ch4_i_late),
                        .q_late(ch4_q_late),
                        .carrier_val(ch4_carrier_val),
                        .code_val(ch4_code_val),
                        .epoch_load(ch4_epoch_load),
                        .epoch(ch4_epoch),
                        .epoch_check(ch4_epoch_check));

  tracking_channel tc5 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch5_carr_nco),
                        .code_nco_fc(ch5_code_nco),
                        .prn_key(ch5_prn_key),
                        .prn_key_enable(ch5_prn_key_enable),
                        .code_slew(ch5_code_slew),
                        .slew_enable(ch5_slew_enable),
                        .epoch_enable(ch5_epoch_enable),
                        .dump(ch5_dump),
                        .i_early(ch5_i_early),
                        .q_early(ch5_q_early),
                        .i_prompt(ch5_i_prompt),
                        .q_prompt(ch5_q_prompt),
                        .i_late(ch5_i_late),
                        .q_late(ch5_q_late),
                        .carrier_val(ch5_carrier_val),
                        .code_val(ch5_code_val),
                        .epoch_load(ch5_epoch_load),
                        .epoch(ch5_epoch),
                        .epoch_check(ch5_epoch_check));

  tracking_channel tc6 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch6_carr_nco),
                        .code_nco_fc(ch6_code_nco),
                        .prn_key(ch6_prn_key),
                        .prn_key_enable(ch6_prn_key_enable),
                        .code_slew(ch6_code_slew),
                        .slew_enable(ch6_slew_enable),
                        .epoch_enable(ch6_epoch_enable),
                        .dump(ch6_dump),
                        .i_early(ch6_i_early),
                        .q_early(ch6_q_early),
                        .i_prompt(ch6_i_prompt),
                        .q_prompt(ch6_q_prompt),
                        .i_late(ch6_i_late),
                        .q_late(ch6_q_late),
                        .carrier_val(ch6_carrier_val),
                        .code_val(ch6_code_val),
		                  .epoch_load(ch6_epoch_load),
                        .epoch(ch6_epoch),
                        .epoch_check(ch6_epoch_check));

  tracking_channel tc7 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch7_carr_nco),
                        .code_nco_fc(ch7_code_nco),
                        .prn_key(ch7_prn_key),
                        .prn_key_enable(ch7_prn_key_enable),
                        .code_slew(ch7_code_slew),
                        .slew_enable(ch7_slew_enable),
                        .epoch_enable(ch7_epoch_enable),
                        .dump(ch7_dump),
                        .i_early(ch7_i_early),
                        .q_early(ch7_q_early),
                        .i_prompt(ch7_i_prompt),
                        .q_prompt(ch7_q_prompt),
                        .i_late(ch7_i_late),
                        .q_late(ch7_q_late),
                        .carrier_val(ch7_carrier_val),
                        .code_val(ch7_code_val),
                        .epoch_load(ch7_epoch_load),
                        .epoch(ch7_epoch),
                        .epoch_check(ch7_epoch_check));

  tracking_channel tc8 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch8_carr_nco),
                        .code_nco_fc(ch8_code_nco),
                        .prn_key(ch8_prn_key),
                        .prn_key_enable(ch8_prn_key_enable),
                        .code_slew(ch8_code_slew),
                        .slew_enable(ch8_slew_enable),
                        .epoch_enable(ch8_epoch_enable),
                        .dump(ch8_dump),
                        .i_early(ch8_i_early),
                        .q_early(ch8_q_early),
                        .i_prompt(ch8_i_prompt),
                        .q_prompt(ch8_q_prompt),
                        .i_late(ch8_i_late),
                        .q_late(ch8_q_late),
                        .carrier_val(ch8_carrier_val),
                        .code_val(ch8_code_val),
                        .epoch_load(ch8_epoch_load),
                        .epoch(ch8_epoch),
                        .epoch_check(ch8_epoch_check));

  tracking_channel tc9 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch9_carr_nco),
                        .code_nco_fc(ch9_code_nco),
                        .prn_key(ch9_prn_key),
                        .prn_key_enable(ch9_prn_key_enable),
                        .code_slew(ch9_code_slew),
                        .slew_enable(ch9_slew_enable),
                        .epoch_enable(ch9_epoch_enable),
                        .dump(ch9_dump),
                        .i_early(ch9_i_early),
                        .q_early(ch9_q_early),
                        .i_prompt(ch9_i_prompt),
                        .q_prompt(ch9_q_prompt),
                        .i_late(ch9_i_late),
                        .q_late(ch9_q_late),
                        .carrier_val(ch9_carrier_val),
                        .code_val(ch9_code_val),
                        .epoch_load(ch9_epoch_load),
                        .epoch(ch9_epoch),
                        .epoch_check(ch9_epoch_check));

/*  tracking_channel tc10 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch10_carr_nco),
                        .code_nco_fc(ch10_code_nco),
                        .prn_key(ch10_prn_key),
                        .prn_key_enable(ch10_prn_key_enable),
                        .code_slew(ch10_code_slew),
                        .slew_enable(ch10_slew_enable),
                        .epoch_enable(ch10_epoch_enable),
                        .dump(ch10_dump),
                        .i_early(ch10_i_early),
                        .q_early(ch10_q_early),
                        .i_prompt(ch10_i_prompt),
                        .q_prompt(ch10_q_prompt),
                        .i_late(ch10_i_late),
                        .q_late(ch10_q_late),
                        .carrier_val(ch10_carrier_val),
                        .code_val(ch10_code_val),
                        .epoch_load(ch10_epoch_load),
                        .epoch(ch10_epoch),
                        .epoch_check(ch10_epoch_check));

  tracking_channel tc11 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch11_carr_nco),
                        .code_nco_fc(ch11_code_nco),
                        .prn_key(ch11_prn_key),
                        .prn_key_enable(ch11_prn_key_enable),
                        .code_slew(ch11_code_slew),
                        .slew_enable(ch11_slew_enable),
                        .epoch_enable(ch11_epoch_enable),
                        .dump(ch11_dump),
                        .i_early(ch11_i_early),
                        .q_early(ch11_q_early),
                        .i_prompt(ch11_i_prompt),
                        .q_prompt(ch11_q_prompt),
                        .i_late(ch11_i_late),
                        .q_late(ch11_q_late),
                        .carrier_val(ch11_carrier_val),
                        .code_val(ch11_code_val),
                        .epoch_load(ch11_epoch_load),
                        .epoch(ch11_epoch),
                        .epoch_check(ch11_epoch_check));*/
                       	     
  // address decoder ----------------------------------
	  
  always @ (posedge clk)
  begin
  if (!hw_rstn)
  begin
    // Need to initialize nco's (at least for simulation) or they don't run.
    ch0_carr_nco <= 0;
    ch0_code_nco <= 0;
/*    ch1_carr_nco <= 0;
    ch1_code_nco <= 0;
    ch2_carr_nco <= 0;
    ch2_code_nco <= 0;
    ch3_carr_nco <= 0;
    ch3_code_nco <= 0;
    ch4_carr_nco <= 0;
    ch4_code_nco <= 0;
    ch5_carr_nco <= 0;
    ch5_code_nco <= 0;
    ch6_carr_nco <= 0;
    ch6_code_nco <= 0;
    ch7_carr_nco <= 0;
    ch7_code_nco <= 0;
    ch8_carr_nco <= 0;
    ch8_code_nco <= 0;
    ch9_carr_nco <= 0;
    ch9_code_nco <= 0;
    ch10_carr_nco <= 0;
    ch10_code_nco <= 0;
    ch11_carr_nco <= 0;
    ch11_code_nco <= 0;*///[Art] temp!
    // Anything else need initializing here?
  end
  else

    case (address)
      // channel 0
      10'h00 : 
      begin
        ch0_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch0_prn_key <= data[9:0];
      end
      10'h02 : if (!wen & !csn) ch0_carr_nco_low <=  data[15:0];
      10'h04 : if (!wen & !csn) ch0_carr_nco     <= {data[12:0], ch0_carr_nco_low};
      10'h06 : if (!wen & !csn) ch0_code_nco_low <=  data[15:0];
      10'h08 : if (!wen & !csn) ch0_code_nco     <= {data[11:0], ch0_code_nco_low};
      10'h0A : 
      begin
        ch0_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch0_code_slew <= data[10:0];
      end
      10'h0C : data_out <= ch0_i_early; //[Art]
      10'h0E : data_out <= ch0_q_early; //[Art]			 
      10'h10 : data_out <= ch0_i_prompt;//[Art]			 
      10'h12 : data_out <= ch0_q_prompt;//[Art]     		 
      10'h14 : data_out <= ch0_i_late;  //[Art]
      10'h16 : data_out <= ch0_q_late;  //[Art]
      10'h18 : data_out <= ch0_carrier_val[15:0];        // 16 bits low
      10'h18 : data_out <= ch0_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'h1A : data_out <= ch0_code_val[15:0];           // 16 bits low
      10'h1A : data_out <= {11'h0, ch0_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'h1C : data_out <= {5'h0, ch0_epoch};            // 11 bits //[Art]
      10'h1E : data_out <= {5'h0, ch0_epoch_check};      // 11 bits //[Art]
      10'h20 : 
      begin
        ch0_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch0_epoch_load <= data[10:0];
      end

/*      // channel 1
      8'h10 : 
      begin
        ch1_prn_key_enable <= write & chip_select;
        if (write & chip_select) ch1_prn_key <= write_data[9:0];
      end
      8'h11 : if (write & chip_select) ch1_carr_nco <= write_data[28:0];
      8'h12 : if (write & chip_select) ch1_code_nco <= write_data[27:0];
      8'h13 : 
      begin
        ch1_slew_enable <= write & chip_select;
        if (write & chip_select) ch1_code_slew <= write_data[10:0];
      end
      8'h14 : read_data <= {16'h0, ch1_i_early};
      8'h15 : read_data <= {16'h0, ch1_q_early};			 
      8'h16 : read_data <= {16'h0, ch1_i_prompt};			 
      8'h17 : read_data <= {16'h0, ch1_q_prompt};   	      		 
      8'h18 : read_data <= {16'h0, ch1_i_late};			 
      8'h19 : read_data <= {16'h0, ch1_q_late};   
      8'h1A : read_data <= ch1_carrier_val; // 32 bits
      8'h1B : read_data <= {11'h0, ch1_code_val}; // 21 bits
      8'h1C : read_data <= {21'h0, ch1_epoch}; // 11 bits
      8'h1D : read_data <= {21'h0, ch1_epoch_check};
      8'h1E : 
      begin
        ch1_epoch_enable <= write & chip_select;
        if (write & chip_select) ch1_epoch_load <= write_data[10:0];
      end

      // channel 2
      8'h20 : 
      begin
	     ch2_prn_key_enable <= write & chip_select;
        if (write & chip_select) ch2_prn_key <= write_data[9:0];
      end
      8'h21 : if (write & chip_select) ch2_carr_nco <= write_data[28:0];
      8'h22 : if (write & chip_select) ch2_code_nco <= write_data[27:0];
      8'h23 : 
      begin
	     ch2_slew_enable <= write & chip_select;
        if (write & chip_select) ch2_code_slew <= write_data[10:0];
      end
      8'h24 : read_data <= {16'h0, ch2_i_early};
      8'h25 : read_data <= {16'h0, ch2_q_early};			 
      8'h26 : read_data <= {16'h0, ch2_i_prompt};			 
      8'h27 : read_data <= {16'h0, ch2_q_prompt};   	      		 
      8'h28 : read_data <= {16'h0, ch2_i_late};			 
      8'h29 : read_data <= {16'h0, ch2_q_late};   
      8'h2A : read_data <= ch2_carrier_val; // 32 bits
      8'h2B : read_data <= {11'h0, ch2_code_val}; // 21 bits
      8'h2C : read_data <= {21'h0, ch2_epoch}; // 11 bits
      8'h2D : read_data <= {21'h0, ch2_epoch_check};
      8'h2E : 
      begin
        ch2_epoch_enable <= write & chip_select;
        if (write & chip_select) ch2_epoch_load <= write_data[10:0];
      end

      // channel 3
      8'h30 : 
      begin
        ch3_prn_key_enable <= write & chip_select;
	     if (write & chip_select) ch3_prn_key <= write_data[9:0];
	   end
      8'h31 : if (write & chip_select) ch3_carr_nco <= write_data[28:0];
      8'h32 : if (write & chip_select) ch3_code_nco <= write_data[27:0];
      8'h33 : 
      begin
        ch3_slew_enable <= write & chip_select;
	     if (write & chip_select) ch3_code_slew <= write_data[10:0];
	   end
      8'h34 : read_data <= {16'h0, ch3_i_early};
      8'h35 : read_data <= {16'h0, ch3_q_early};			 
      8'h36 : read_data <= {16'h0, ch3_i_prompt};			 
      8'h37 : read_data <= {16'h0, ch3_q_prompt};   	      		 
      8'h38 : read_data <= {16'h0, ch3_i_late};			 
      8'h39 : read_data <= {16'h0, ch3_q_late};   
      8'h3A : read_data <= ch3_carrier_val; // 32 bits
      8'h3B : read_data <= {11'h0, ch3_code_val}; // 21 bits
      8'h3C : read_data <= {21'h0, ch3_epoch}; // 11 bits
      8'h3D : read_data <= {21'h0, ch3_epoch_check};
      8'h3E : 
		begin
        ch3_epoch_enable <= write & chip_select;
        if (write & chip_select) ch3_epoch_load <= write_data[10:0];
      end

      // channel 4
      8'h40 : 
      begin
        ch4_prn_key_enable <= write & chip_select;
	     if (write & chip_select) ch4_prn_key <= write_data[9:0];
	   end
      8'h41 : if (write & chip_select) ch4_carr_nco <= write_data[28:0];
      8'h42 : if (write & chip_select) ch4_code_nco <= write_data[27:0];
      8'h43 : 
      begin
        ch4_slew_enable <= write & chip_select;
	     if (write & chip_select) ch4_code_slew <= write_data[10:0];
	   end
      8'h44 : read_data <= {16'h0, ch4_i_early};
      8'h45 : read_data <= {16'h0, ch4_q_early};			 
      8'h46 : read_data <= {16'h0, ch4_i_prompt};			 
      8'h47 : read_data <= {16'h0, ch4_q_prompt};   	      		 
      8'h48 : read_data <= {16'h0, ch4_i_late};			 
      8'h49 : read_data <= {16'h0, ch4_q_late};   
      8'h4A : read_data <= ch4_carrier_val; // 32 bits
      8'h4B : read_data <= {11'h0, ch4_code_val}; // 21 bits
      8'h4C : read_data <= {21'h0, ch4_epoch}; // 11 bits
      8'h4D : read_data <= {21'h0, ch4_epoch_check};
      8'h4E : 
      begin
        ch4_epoch_enable <= write & chip_select;
        if (write & chip_select) ch4_epoch_load <= write_data[10:0];
      end

      // channel 5
      8'h50 : 
      begin
        ch5_prn_key_enable <= write & chip_select;
	     if (write & chip_select) ch5_prn_key <= write_data[9:0];
	   end
      8'h51 : if (write & chip_select) ch5_carr_nco <= write_data[28:0];
      8'h52 : if (write & chip_select) ch5_code_nco <= write_data[27:0];
      8'h53 : 
      begin
        ch5_slew_enable <= write & chip_select;
	     if (write & chip_select) ch5_code_slew <= write_data[10:0];
	   end
      8'h54 : read_data <= {16'h0, ch5_i_early};
      8'h55 : read_data <= {16'h0, ch5_q_early};			 
      8'h56 : read_data <= {16'h0, ch5_i_prompt};			 
      8'h57 : read_data <= {16'h0, ch5_q_prompt};   	      		 
      8'h58 : read_data <= {16'h0, ch5_i_late};			 
      8'h59 : read_data <= {16'h0, ch5_q_late};   
      8'h5A : read_data <= ch5_carrier_val; // 32 bits
      8'h5B : read_data <= {11'h0, ch5_code_val}; // 21 bits
      8'h5C : read_data <= {21'h0, ch5_epoch}; // 11 bits
      8'h5D : read_data <= {21'h0, ch5_epoch_check};
      8'h5E : 
      begin
        ch5_epoch_enable <= write & chip_select;
        if (write & chip_select) ch5_epoch_load <= write_data[10:0];
      end

      // channel 6
      8'h60 : 
      begin
        ch6_prn_key_enable <= write & chip_select;
	     if (write & chip_select) ch6_prn_key <= write_data[9:0];
	   end
      8'h61 : if (write & chip_select) ch6_carr_nco <= write_data[28:0];
      8'h62 : if (write & chip_select) ch6_code_nco <= write_data[27:0];
      8'h63 : 
      begin
        ch6_slew_enable <= write & chip_select;
	     if (write & chip_select) ch6_code_slew <= write_data[10:0];
	   end
      8'h64 : read_data <= {16'h0, ch6_i_early};
      8'h65 : read_data <= {16'h0, ch6_q_early};			 
      8'h66 : read_data <= {16'h0, ch6_i_prompt};			 
      8'h67 : read_data <= {16'h0, ch6_q_prompt};   	      		 
      8'h68 : read_data <= {16'h0, ch6_i_late};			 
      8'h69 : read_data <= {16'h0, ch6_q_late};   
      8'h6A : read_data <= ch6_carrier_val; // 32 bits
      8'h6B : read_data <= {11'h0, ch6_code_val}; // 21 bits
      8'h6C : read_data <= {21'h0, ch6_epoch}; // 11 bits
      8'h6D : read_data <= {21'h0, ch6_epoch_check};
      8'h6E : 
      begin
        ch6_epoch_enable <= write & chip_select;
        if (write & chip_select) ch6_epoch_load <= write_data[10:0];
      end

      // channel 7
      8'h70 : 
      begin
	     ch7_prn_key_enable <= write & chip_select;
	     if (write & chip_select) ch7_prn_key <= write_data[9:0];
	   end
      8'h71 : if (write & chip_select) ch7_carr_nco <= write_data[28:0];
      8'h72 : if (write & chip_select) ch7_code_nco <= write_data[27:0];
      8'h73 : 
      begin
        ch7_slew_enable <= write & chip_select;
	     if (write & chip_select) ch7_code_slew <= write_data[10:0];
	   end
      8'h74 : read_data <= {16'h0, ch7_i_early};
      8'h75 : read_data <= {16'h0, ch7_q_early};			 
      8'h76 : read_data <= {16'h0, ch7_i_prompt};			 
      8'h77 : read_data <= {16'h0, ch7_q_prompt};   	      		 
      8'h78 : read_data <= {16'h0, ch7_i_late};			 
      8'h79 : read_data <= {16'h0, ch7_q_late};   
      8'h7A : read_data <= ch7_carrier_val; // 32 bits
      8'h7B : read_data <= {11'h0, ch7_code_val}; // 21 bits
      8'h7C : read_data <= {21'h0, ch7_epoch}; // 11 bits
      8'h7D : read_data <= {21'h0, ch7_epoch_check};
      8'h7E : 
      begin
        ch7_epoch_enable <= write & chip_select;
        if (write & chip_select) ch7_epoch_load <= write_data[10:0];
      end

      // channel 8
      8'h80 : 
      begin
        ch8_prn_key_enable <= write & chip_select;
	     if (write & chip_select) ch8_prn_key <= write_data[9:0];
	   end
      8'h81 : if (write & chip_select) ch8_carr_nco <= write_data[28:0];
      8'h82 : if (write & chip_select) ch8_code_nco <= write_data[27:0];
      8'h83 : 
      begin
       ch8_slew_enable <= write & chip_select;
	    if (write & chip_select) ch8_code_slew <= write_data[10:0];
	   end
      8'h84 : read_data <= {16'h0, ch8_i_early};
      8'h85 : read_data <= {16'h0, ch8_q_early};			 
      8'h86 : read_data <= {16'h0, ch8_i_prompt};			 
      8'h87 : read_data <= {16'h0, ch8_q_prompt};   	      		 
      8'h88 : read_data <= {16'h0, ch8_i_late};			 
      8'h89 : read_data <= {16'h0, ch8_q_late};   
      8'h8A : read_data <= ch8_carrier_val; // 32 bits
      8'h8B : read_data <= {11'h0, ch8_code_val}; // 21 bits
      8'h8C : read_data <= {21'h0, ch8_epoch}; // 11 bits
      8'h8D : read_data <= {21'h0, ch8_epoch_check};
      8'h8E : 
      begin
        ch8_epoch_enable <= write & chip_select;
        if (write & chip_select) ch8_epoch_load <= write_data[10:0];
      end

      // channel 9
      8'h90 : 
      begin
        ch9_prn_key_enable <= write & chip_select;
	     if (write & chip_select) ch1_prn_key <= write_data[9:0];
	   end
      8'h91 : if (write & chip_select) ch9_carr_nco <= write_data[28:0];
      8'h92 : if (write & chip_select) ch9_code_nco <= write_data[27:0];
      8'h93 : 
      begin
        ch9_slew_enable <= write & chip_select;
	     if (write & chip_select) ch9_code_slew <= write_data[10:0];
	   end
      8'h94 : read_data <= {16'h0, ch9_i_early};
      8'h95 : read_data <= {16'h0, ch9_q_early};			 
      8'h96 : read_data <= {16'h0, ch9_i_prompt};			 
      8'h97 : read_data <= {16'h0, ch9_q_prompt};   	      		 
      8'h98 : read_data <= {16'h0, ch9_i_late};			 
      8'h99 : read_data <= {16'h0, ch9_q_late};   
      8'h9A : read_data <= ch9_carrier_val; // 32 bits
      8'h9B : read_data <= {11'h0, ch9_code_val}; // 21 bits
      8'h9C : read_data <= {21'h0, ch9_epoch}; // 11 bits
      8'h9D : read_data <= {21'h0, ch9_epoch_check};
      8'h9E : 
      begin
        ch9_epoch_enable <= write & chip_select;
        if (write & chip_select) ch9_epoch_load <= write_data[10:0];
      end

      // channel 10
      8'hA0 : 
		begin
        ch10_prn_key_enable <= write & chip_select;
	     if (write & chip_select) ch10_prn_key <= write_data[9:0];
	   end
      8'hA1 : if (write & chip_select) ch10_carr_nco <= write_data[28:0];
      8'hA2 : if (write & chip_select) ch10_code_nco <= write_data[27:0];
      8'hA3 : 
      begin
        ch10_slew_enable <= write & chip_select;
	     if (write & chip_select) ch1_code_slew <= write_data[10:0];
	   end
      8'hA4 : read_data <= {16'h0, ch10_i_early};
      8'hA5 : read_data <= {16'h0, ch10_q_early};			 
      8'hA6 : read_data <= {16'h0, ch10_i_prompt};			 
      8'hA7 : read_data <= {16'h0, ch10_q_prompt};   	      		 
      8'hA8 : read_data <= {16'h0, ch10_i_late};			 
      8'hA9 : read_data <= {16'h0, ch10_q_late};   
      8'hAA : read_data <= ch10_carrier_val; // 32 bits
      8'hAB : read_data <= {11'h0, ch10_code_val}; // 21 bits
      8'hAC : read_data <= {21'h0, ch10_epoch}; // 11 bits
      8'hAD : read_data <= {21'h0, ch10_epoch_check};
      8'hAE : 
      begin
        ch10_epoch_enable <= write & chip_select;
        if (write & chip_select) ch10_epoch_load <= write_data[10:0];
      end

      // channel 11
      8'hB0 : 
      begin
        ch11_prn_key_enable <= write & chip_select;
	     if (write & chip_select) ch11_prn_key <= write_data[9:0];
	   end
      8'hB1 : if (write & chip_select) ch11_carr_nco <= write_data[28:0];
      8'hB2 : if (write & chip_select) ch11_code_nco <= write_data[27:0];
      8'hB3 : 
      begin
        ch11_slew_enable <= write & chip_select;
	     if (write & chip_select) ch11_code_slew <= write_data[10:0];
	   end
      8'hB4 : read_data <= {16'h0, ch11_i_early};
      8'hB5 : read_data <= {16'h0, ch11_q_early};			 
      8'hB6 : read_data <= {16'h0, ch11_i_prompt};			 
      8'hB7 : read_data <= {16'h0, ch11_q_prompt};   	      		 
      8'hB8 : read_data <= {16'h0, ch11_i_late};			 
      8'hB9 : read_data <= {16'h0, ch11_q_late};   
      8'hBA : read_data <= ch11_carrier_val; // 32 bits
      8'hBB : read_data <= {11'h0, ch11_code_val}; // 21 bits
      8'hBC : read_data <= {21'h0, ch11_epoch}; // 11 bits
      8'hBD : read_data <= {21'h0, ch11_epoch_check};       
      8'hBE : 
      begin
        ch11_epoch_enable <= write & chip_select;
        if (write & chip_select) ch11_epoch_load <= write_data[10:0];
      end*/

      // status
      10'hE0 : 
      begin // get status and pulse status_flag to clear status
        data_out    <= {14'h0, status}; // only 2 status bits, therefore need to pad 30ms bits
      end
      10'hE2 : 
      begin // get new_data
        data_out <= {4'h0,new_data};    // one new_data bit per channel, need to pad other bits
      end
      10'hE4 : 
      begin // tic count read low bits
        data_out <= tic_count[15:0];           // 16 low bits of TIC count
      end
      10'hE6 : 
      begin // tic count read high bits
        data_out <= {8'h0,tic_count[23:16]};   // 8 high bits of TIC count
      end
      10'hE8 : 
      begin // accum count read low bits
        data_out <= accum_count[15:0];         // 16 low bits of accum count
      end
      10'hEA : 
      begin // accum count read high bits
        data_out <= {8'h0,accum_count[23:16]}; // 8 high bits of accum count
      end

      // control
      10'hF2 : if (!wen & !csn) prog_tic       <= data[15:0]; // program TIC_low
      10'hF4 : if (!wen & !csn) prog_tic       <= data[7:0];  // program TIC_high
      10'hF6 : if (!wen & !csn) prog_accum_int <= data[15:0]; // program ACCUM_INT_low
      10'hF8 : if (!wen & !csn) prog_accum_int <= data[7:0];  // program ACCUM_INT_high
       
      default : data_out <= 16'b0000000000000000;

    endcase // case(address)
  end

  //Add condiotional synthesis here.
  initial begin //For testing only;
    new_data        = 12'b000000000000;
    new_data_miss   = 12'b000000000000;

    status          = 2'b00;
    status_miss     = 2'b00;
  end
  //Add condiotional synthesis here - END.
  
  wire sw_rst        = ( (address == 8'hF0) & (!wen) & (!csn) );
  wire new_data_read = ( (address == 8'hE1) & (!oen)  & (!csn) );
  wire status_read   = ( (address == 8'hE0) & (!oen)  & (!csn) );
  assign rstn = hw_rstn & ~sw_rst;

  /* FSM1 for new_data_read processing */
  reg [1:0] ndr_state;
  reg [1:0] ndr_next_state;
  
  parameter NO_NEW_DATA_READ_STATE	= 2'd0;
  parameter NEW_DATA_READ_STATE		= 2'd1;
  
  always @(posedge clk) 
  begin
    if(!rstn)
      ndr_state <= NO_NEW_DATA_READ_STATE;
    else
      ndr_state <= ndr_next_state;
  end
  
  always @(*) //This process controls the next state.
  begin
    ndr_next_state = ndr_state;
        
    case(ndr_state)
      
      NO_NEW_DATA_READ_STATE: 
      begin
        if (new_data_read) ndr_next_state = NEW_DATA_READ_STATE;
      end
      
      NEW_DATA_READ_STATE: 
      begin
        if (!new_data_read)
          ndr_next_state = NO_NEW_DATA_READ_STATE;
      end
      
    endcase
  end
  
  always @(*) //This process is responsible for actions in each state.
  begin
    case(ndr_state)
  
      NO_NEW_DATA_READ_STATE:
      begin
        if (new_data_read)
        begin
          if (ch0_dump)  new_data_miss[0]  <= 1'b1;
          if (ch1_dump)  new_data_miss[1]  <= 1'b1;
          if (ch2_dump)  new_data_miss[2]  <= 1'b1;
          if (ch3_dump)  new_data_miss[3]  <= 1'b1;
          if (ch4_dump)  new_data_miss[4]  <= 1'b1;
          if (ch5_dump)  new_data_miss[5]  <= 1'b1;
          if (ch6_dump)  new_data_miss[6]  <= 1'b1;
          if (ch7_dump)  new_data_miss[7]  <= 1'b1;
          if (ch8_dump)  new_data_miss[8]  <= 1'b1;
          if (ch9_dump)  new_data_miss[9]  <= 1'b1;
          if (ch10_dump) new_data_miss[10] <= 1'b1;
          if (ch11_dump) new_data_miss[11] <= 1'b1;
          
          new_data_old <= new_data;
        end
        else
        begin
          if (ch0_dump)  new_data[0]  <= 1'b1;
          if (ch1_dump)  new_data[1]  <= 1'b1;
          if (ch2_dump)  new_data[2]  <= 1'b1;
          if (ch3_dump)  new_data[3]  <= 1'b1;
          if (ch4_dump)  new_data[4]  <= 1'b1;
          if (ch5_dump)  new_data[5]  <= 1'b1;
          if (ch6_dump)  new_data[6]  <= 1'b1;
          if (ch7_dump)  new_data[7]  <= 1'b1;
          if (ch8_dump)  new_data[8]  <= 1'b1;
          if (ch9_dump)  new_data[9]  <= 1'b1;
          if (ch10_dump) new_data[10] <= 1'b1;
          if (ch11_dump) new_data[11] <= 1'b1;
          
          new_data_miss <= 12'b000000000000;
        end
      end
      
      NEW_DATA_READ_STATE:
      begin
        if (!new_data_read)
        begin
          if (ch0_dump  | new_data_miss[0])  new_data[0]  <= 1'b1; else if (new_data_old[0])  new_data[0]  <= 1'b0;
          if (ch1_dump  | new_data_miss[1])  new_data[1]  <= 1'b1; else if (new_data_old[1])  new_data[1]  <= 1'b0;
          if (ch2_dump  | new_data_miss[2])  new_data[2]  <= 1'b1; else if (new_data_old[2])  new_data[2]  <= 1'b0;
          if (ch3_dump  | new_data_miss[3])  new_data[3]  <= 1'b1; else if (new_data_old[3])  new_data[3]  <= 1'b0;
          if (ch4_dump  | new_data_miss[4])  new_data[4]  <= 1'b1; else if (new_data_old[4])  new_data[4]  <= 1'b0;
          if (ch5_dump  | new_data_miss[5])  new_data[5]  <= 1'b1; else if (new_data_old[5])  new_data[5]  <= 1'b0;
          if (ch6_dump  | new_data_miss[6])  new_data[6]  <= 1'b1; else if (new_data_old[6])  new_data[6]  <= 1'b0;
          if (ch7_dump  | new_data_miss[7])  new_data[7]  <= 1'b1; else if (new_data_old[7])  new_data[7]  <= 1'b0;
          if (ch8_dump  | new_data_miss[8])  new_data[8]  <= 1'b1; else if (new_data_old[8])  new_data[8]  <= 1'b0;
          if (ch9_dump  | new_data_miss[9])  new_data[9]  <= 1'b1; else if (new_data_old[9])  new_data[9]  <= 1'b0;
          if (ch10_dump | new_data_miss[10]) new_data[10] <= 1'b1; else if (new_data_old[10]) new_data[10] <= 1'b0;
          if (ch11_dump | new_data_miss[11]) new_data[11] <= 1'b1; else if (new_data_old[11]) new_data[11] <= 1'b0;
        end
        else
        begin
          if (ch0_dump)  new_data_miss[0]  <= 1'b1;
          if (ch1_dump)  new_data_miss[1]  <= 1'b1;
          if (ch2_dump)  new_data_miss[2]  <= 1'b1;
          if (ch3_dump)  new_data_miss[3]  <= 1'b1;
          if (ch4_dump)  new_data_miss[4]  <= 1'b1;
          if (ch5_dump)  new_data_miss[5]  <= 1'b1;
          if (ch6_dump)  new_data_miss[6]  <= 1'b1;
          if (ch7_dump)  new_data_miss[7]  <= 1'b1;
          if (ch8_dump)  new_data_miss[8]  <= 1'b1;
          if (ch9_dump)  new_data_miss[9]  <= 1'b1;
          if (ch10_dump) new_data_miss[10] <= 1'b1;
          if (ch11_dump) new_data_miss[11] <= 1'b1;
        end
      end
      
    endcase
  end
  /* FSM1 END */

  /* FSM2 for status_read processing */
  // process to reset the status register after a read
  // also create accum_int signal that is cleared after status read
 
  /*// Important notice: It may make sense to have TIC_periode multiple of accum_int_periode!
  // Otherwise similar to new_data_read proessing scheme must be done!!!
  always @ (posedge clk)
  begin
    if (!rstn || status_read)
    begin
      status    <= 0;
      accum_int <= 0;
    end
    else
    begin
      if (tic_enable)
        status[0] <= 1'b1;
      if (accum_enable_s)
      begin
        status[1] <= 1'b1;
        accum_int <= 1'b1;
      end
    end
  end*/


  reg [1:0] sr_state;
  reg [1:0] sr_next_state;
  
  parameter NO_STATUS_READ_STATE	= 2'd0;
  parameter STATUS_READ_STATE		= 2'd1;
  
  always @(posedge clk) 
  begin
    if(!rstn)
      sr_state <= NO_STATUS_READ_STATE;
    else
      sr_state <= sr_next_state;
  end
  
  always @(*) //This process controls the next state.
  begin
    sr_next_state = sr_state;
        
    case(sr_state)
      
      NO_STATUS_READ_STATE: 
      begin
        if (status_read) sr_next_state = STATUS_READ_STATE;
      end
      
      STATUS_READ_STATE: 
      begin
        if (!status_read)
          sr_next_state = NO_STATUS_READ_STATE;
      end
      
    endcase
  end
  
  always @(*) //This process is responsible for actions in each state.
  begin
    case(sr_state)
  
      NO_STATUS_READ_STATE:
      begin
        if (status_read)
        begin
          if (tic_enable)     status_miss[0] <= 1'b1;
          if (accum_enable_s) status_miss[1] <= 1'b1;
          
          status_old <= status;
        end
        else
        begin
          if (tic_enable)     status[0] <= 1'b1;
          if (accum_enable_s) status[1] <= 1'b1;
          
          status_miss <= 2'b00;
        end
      end
      
      STATUS_READ_STATE:
      begin
        if (!status_read)
        begin
          if (tic_enable     | status_miss[0]) status[0] <= 1'b1; else if (status_old[0]) status[0] <= 1'b0;
          if (accum_enable_s | status_miss[1]) status[1] <= 1'b1; else if (status_old[1]) status[1] <= 1'b0;
        end
        else
        begin
          if (tic_enable)     status_miss[0] <= 1'b1;
          if (accum_enable_s) status_miss[1] <= 1'b1;
        end
      end
      
    endcase
  end

  assign accum_int = status[1];

  /* FSM2 END */

  /*Async memory databus routines:*/
  always @(clk)
  begin
    if(!rstn)
    begin
      
    end
    else
    begin
      csn_1 <= csn_a;
      csn   <= csn_1;
      wen_1 <= wen_a;
      wen   <= wen_1;
      oen_1 <= oen_a;
      oen   <= oen_1;
    end
  end
  /*Async memory databus routines - END*/

  assign data = (!oen && !csn) ? data_out : 16'hzz;//[Art]
  
endmodule // gps_baseband
			 
			 
			 