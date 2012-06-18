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

`include "namuro_gnss_setup.v"

module gps_baseband_16bit_async_mem_bus (
                                         `ifdef ENABLE_VERILATOR_SIMULATION
                                         clk,
                                         `else
                                         extclk,
                                         `endif
                                         `ifdef ENABLE_HWRSTN
                                         hw_rstn,
                                         `endif
                                         //input from front-end:
                                         sign, 
                                         `ifdef ENABLE_IQ_PROCESSING
                                         sign_q, 
                                         `endif
                                         `ifndef ENABLE_1_BIT_SAMPLES 
                                         mag,
                                         `ifdef ENABLE_IQ_PROCESSING
                                         mag_q, 
                                         `endif
                                         `endif
                                         //external interface:
                                         csn_a, wen_a, oen_a,//[Art]
                                         address_a, data, //[Art]
                                         `ifdef ENABLE_VERILATOR_SIMULATION
                                         data_out, //[Art] This is only for verilator simulation!!!
                                         `endif
                                         //interrupt for mcu:
                                         accum_int
                                         //test points for FPGA:
                                         `ifdef ENABLE_DEBUG_SIGNALS_OUTPUT
                                         ,test_point_01, test_point_02, test_point_03,
                                         test_point_04, test_point_05
                                         `endif
                                         `ifdef ENABLE_VERILATOR_SIMULATION
                                         ,test_point_001, test_point_002, test_point_003 //for verilator only.
                                         `endif
		                        );

  `ifdef ENABLE_VERILATOR_SIMULATION
  input clk;
  `else
  input extclk;
  `endif
  `ifdef ENABLE_HWRSTN
  input hw_rstn;
  `endif
  input sign;// raw data in from RF front end
  `ifdef ENABLE_IQ_PROCESSING
  input sign_q;
  `endif
  `ifndef ENABLE_1_BIT_SAMPLES 
  input mag;
  `ifdef ENABLE_IQ_PROCESSING
  input mag_q;
  `endif
  `endif
  input csn_a, wen_a, oen_a;
  input [9:0] address_a;
  `ifdef ENABLE_VERILATOR_SIMULATION
  input [15:0] data;
  `else
  inout [15:0] data;
  `endif
  output accum_int; // interrupt pulse to tell FW to collect accumulation data, cleared on STATUS read
  `ifdef ENABLE_DEBUG_SIGNALS_OUTPUT
  output test_point_01, test_point_02, test_point_03, test_point_04, test_point_05;
  `endif
  `ifdef ENABLE_VERILATOR_SIMULATION
  output reg [31:0] test_point_001, test_point_002, test_point_003;
  `endif
  
  `ifdef ENABLE_VERILATOR_SIMULATION
  output [15:0] data_out;
  `else
  reg [15:0] data_out;
  `endif
  
  `ifdef ENABLE_1_BIT_SAMPLES 
  wire mag = 1'b0;
  `ifdef ENABLE_IQ_PROCESSING
  wire mag_q = 1'b0;
  `endif
  `endif
  `ifndef ENABLE_HWRSTN
  wire hw_rstn = 1'b1;
  `endif

  wire accum_enable_s;
  wire pre_tic_enable, tic_enable, accum_sample_enable;

  wire [23:0] tic_count;
  wire [23:0] accum_count;

  wire rstn; // software generated reset. 

  // channel 0 registers
  `ifdef ENABLE_GLONASS
  reg ch0_glns_or_gps;
  `endif
  reg [9:0]  ch0_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch0_carr_nco_sign;      //[Art]
  `endif
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
  
  `ifndef ENABLE_SINGLE_CHANNEL
  // channel 1 registers
  `ifdef ENABLE_GLONASS
  reg ch1_glns_or_gps;
  `endif
  reg [9:0]  ch1_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch1_carr_nco_sign;      //[Art]
  `endif
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
  `ifdef ENABLE_GLONASS
  reg ch2_glns_or_gps;
  `endif
  reg [9:0]  ch2_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch2_carr_nco_sign;      //[Art]
  `endif
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
  `ifdef ENABLE_GLONASS
  reg ch3_glns_or_gps;
  `endif
  reg [9:0]  ch3_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch3_carr_nco_sign;      //[Art]
  `endif
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
  `ifdef ENABLE_GLONASS
  reg ch4_glns_or_gps;
  `endif
  reg [9:0]  ch4_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch4_carr_nco_sign;      //[Art]
  `endif
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
  `ifdef ENABLE_GLONASS
  reg ch5_glns_or_gps;
  `endif
  reg [9:0]  ch5_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch5_carr_nco_sign;      //[Art]
  `endif
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

  `ifndef ENABLE_LIMITED_VERSION
  // channel 6 registers
  `ifdef ENABLE_GLONASS
  reg ch6_glns_or_gps;
  `endif
  reg [9:0]  ch6_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch6_carr_nco_sign;      //[Art]
  `endif
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
  `ifdef ENABLE_GLONASS
  reg ch7_glns_or_gps;
  `endif
  reg [9:0]  ch7_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch7_carr_nco_sign;      //[Art]
  `endif
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
  `ifdef ENABLE_GLONASS
  reg ch8_glns_or_gps;
  `endif
  reg [9:0]  ch8_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch8_carr_nco_sign;      //[Art]
  `endif
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
  `ifdef ENABLE_GLONASS
  reg ch9_glns_or_gps;
  `endif
  reg [9:0]  ch9_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch9_carr_nco_sign;      //[Art]
  `endif
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

  `ifndef ENABLE_LIMITED_VERSION_2
  // channel 10 registers
  `ifdef ENABLE_GLONASS
  reg ch10_glns_or_gps;
  `endif
  reg [9:0]  ch10_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch10_carr_nco_sign;      //[Art]
  `endif
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
  `ifdef ENABLE_GLONASS
  reg ch11_glns_or_gps;
  `endif
  reg [9:0]  ch11_prn_key;
  `ifdef ENABLE_IQ_PROCESSING
  reg ch11_carr_nco_sign;      //[Art]
  `endif
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
  `endif
  `endif
  `endif
  
  // status registers
  reg [1:0] status;      // TIC = bit 0, ACCUM_INT = bit 1, cleared on read
  reg [1:0] status_miss; //[Art] //The same as status but used during bus-read process instead of status.

  reg [11:0] new_data;      // chan0 = bit 0, chan1 = bit 1 etc, cleared on read.
  reg [11:0] new_data_miss; //[Art] //The same as new_data but used during bus-read process instead of new_data.

  // control registers
  reg [23:0] prog_tic;
  reg [23:0] prog_accum_int;

  //memory for testing wishbone-interface:
  reg [15:0] test_memory [0:7];	//eight 32-bit-wide words;

  //async memory flip-flops to prevent metastability:
  reg csn_1, csn;
  reg wen_1, wen;
  reg oen_1, oen;
  reg [9:0]  address_1, address;

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
   
  // connect up tracking channels
  tracking_channel tc0 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch0_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch0_carr_nco),
                        .code_nco_fc(ch0_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch0_glns_or_gps),
                        `endif
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

  `ifndef ENABLE_SINGLE_CHANNEL
  tracking_channel tc1 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch1_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch1_carr_nco),
                        .code_nco_fc(ch1_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch1_glns_or_gps),
                        `endif
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
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch2_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch2_carr_nco),
                        .code_nco_fc(ch2_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch2_glns_or_gps),
                        `endif
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
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch3_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch3_carr_nco),
                        .code_nco_fc(ch3_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch3_glns_or_gps),
                        `endif
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
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch4_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch4_carr_nco),
                        .code_nco_fc(ch4_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch4_glns_or_gps),
                        `endif
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
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch5_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch5_carr_nco),
                        .code_nco_fc(ch5_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch5_glns_or_gps),
                        `endif
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

  `ifndef ENABLE_LIMITED_VERSION
  tracking_channel tc6 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch6_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch6_carr_nco),
                        .code_nco_fc(ch6_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch6_glns_or_gps),
                        `endif
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
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch7_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch7_carr_nco),
                        .code_nco_fc(ch7_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch7_glns_or_gps),
                        `endif
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
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch8_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch8_carr_nco),
                        .code_nco_fc(ch8_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch8_glns_or_gps),
                        `endif
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
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch9_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch9_carr_nco),
                        .code_nco_fc(ch9_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch9_glns_or_gps),
                        `endif
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

  `ifndef ENABLE_LIMITED_VERSION_2
  tracking_channel tc10 (.clk(clk), .rstn(rstn),
                        .accum_sample_enable(accum_sample_enable),
                        .if_sign(sign), .if_mag(mag),
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch10_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch10_carr_nco),
                        .code_nco_fc(ch10_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch10_glns_or_gps),
                        `endif
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
                        `ifdef ENABLE_IQ_PROCESSING
                        .if_sign_q(sign_q), .if_mag_q(mag_q),
                        .carr_nco_fc_sign(ch11_carr_nco_sign),
                        `endif
                        .pre_tic_enable(pre_tic_enable),
                        .tic_enable(tic_enable),
                        .carr_nco_fc(ch11_carr_nco),
                        .code_nco_fc(ch11_code_nco),
                        `ifdef ENABLE_GLONASS
                        .glns_or_gps(ch11_glns_or_gps),
                        `endif
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
                        .epoch_check(ch11_epoch_check));
  `endif
  `endif
  `endif
                       	     
  // address decoder ----------------------------------
	  
  always @ (posedge clk)
  begin
  if (!hw_rstn)
  begin
    // Need to initialize nco's (at least for simulation) or they don't run.
    ch0_carr_nco <= 0;
    ch0_code_nco <= 0;
    `ifndef ENABLE_SINGLE_CHANNEL
    ch1_carr_nco <= 0;
    ch1_code_nco <= 0;
    ch2_carr_nco <= 0;
    ch2_code_nco <= 0;
    ch3_carr_nco <= 0;
    ch3_code_nco <= 0;
    ch4_carr_nco <= 0;
    ch4_code_nco <= 0;
    ch5_carr_nco <= 0;
    ch5_code_nco <= 0;
    `ifndef ENABLE_LIMITED_VERSION
    ch6_carr_nco <= 0;
    ch6_code_nco <= 0;
    ch7_carr_nco <= 0;
    ch7_code_nco <= 0;
    ch8_carr_nco <= 0;
    ch8_code_nco <= 0;
    ch9_carr_nco <= 0;
    ch9_code_nco <= 0;
    `ifndef ENABLE_LIMITED_VERSION_2
    ch10_carr_nco <= 0;
    ch10_code_nco <= 0;
    ch11_carr_nco <= 0;
    ch11_code_nco <= 0;
    `endif
    `endif
    `endif
    // Anything else need initializing here?
  end
  else

    case (address)
      // channel 0
      10'h00 : 
      begin
        ch0_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch0_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch0_glns_or_gps <= data[10];
        `endif
      end
      10'h02 : if (!wen & !csn) ch0_carr_nco_low <=  data[15:0];
      10'h04 : if (!wen & !csn)
               begin
                 ch0_carr_nco      <= {data[12:0], ch0_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch0_carr_nco_sign <= data[15];
                 `endif
               end
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
      10'h1A : data_out <= ch0_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'h1C : data_out <= ch0_code_val[15:0];           // 16 bits low
      10'h1E : data_out <= {11'h0, ch0_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'h20 : data_out <= {5'h0, ch0_epoch};            // 11 bits //[Art]
      10'h22 : data_out <= {5'h0, ch0_epoch_check};      // 11 bits //[Art]
      10'h24 : 
      begin
        ch0_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch0_epoch_load <= data[10:0];
      end

      `ifndef ENABLE_SINGLE_CHANNEL
      // channel 1
      10'h26 :
      begin
        ch1_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch1_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch1_glns_or_gps <= data[10];
        `endif
      end
      10'h28 : if (!wen & !csn) ch1_carr_nco_low <=  data[15:0];
      10'h2A : if (!wen & !csn) 
               begin
                 ch1_carr_nco     <= {data[12:0], ch1_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch1_carr_nco_sign <= data[15];
                 `endif
               end
      10'h2C : if (!wen & !csn) ch1_code_nco_low <=  data[15:0];
      10'h2E : if (!wen & !csn) ch1_code_nco     <= {data[11:0], ch1_code_nco_low};
      10'h30 : 
      begin
        ch1_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch1_code_slew <= data[10:0];
      end
      10'h32 : data_out <= ch1_i_early; //[Art]
      10'h34 : data_out <= ch1_q_early; //[Art]			 
      10'h36 : data_out <= ch1_i_prompt;//[Art]			 
      10'h38 : data_out <= ch1_q_prompt;//[Art]     		 
      10'h3A : data_out <= ch1_i_late;  //[Art]
      10'h3C : data_out <= ch1_q_late;  //[Art]
      10'h3E : data_out <= ch1_carrier_val[15:0];        // 16 bits low
      10'h40 : data_out <= ch1_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'h42 : data_out <= ch1_code_val[15:0];           // 16 bits low
      10'h44 : data_out <= {11'h0, ch1_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'h46 : data_out <= {5'h0, ch1_epoch};            // 11 bits //[Art]
      10'h48 : data_out <= {5'h0, ch1_epoch_check};      // 11 bits //[Art]
      10'h4A : 
      begin
        ch1_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch1_epoch_load <= data[10:0];
      end

      // channel 2
      10'h4C :
      begin
        ch2_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch2_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch2_glns_or_gps <= data[10];
        `endif
      end
      10'h4E : if (!wen & !csn) ch2_carr_nco_low <=  data[15:0];
      10'h50 : if (!wen & !csn) 
               begin
                 ch2_carr_nco     <= {data[12:0], ch2_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch2_carr_nco_sign <= data[15];
                 `endif
               end
      10'h52 : if (!wen & !csn) ch2_code_nco_low <=  data[15:0];
      10'h54 : if (!wen & !csn) ch2_code_nco     <= {data[11:0], ch2_code_nco_low};
      10'h56 : 
      begin
        ch2_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch2_code_slew <= data[10:0];
      end
      10'h58 : data_out <= ch2_i_early; //[Art]
      10'h5A : data_out <= ch2_q_early; //[Art]			 
      10'h5C : data_out <= ch2_i_prompt;//[Art]			 
      10'h5E : data_out <= ch2_q_prompt;//[Art]     		 
      10'h60 : data_out <= ch2_i_late;  //[Art]
      10'h62 : data_out <= ch2_q_late;  //[Art]
      10'h64 : data_out <= ch2_carrier_val[15:0];        // 16 bits low
      10'h66 : data_out <= ch2_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'h68 : data_out <= ch2_code_val[15:0];           // 16 bits low
      10'h6A : data_out <= {11'h0, ch2_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'h6C : data_out <= {5'h0, ch2_epoch};            // 11 bits //[Art]
      10'h6E : data_out <= {5'h0, ch2_epoch_check};      // 11 bits //[Art]
      10'h70 : 
      begin
        ch2_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch2_epoch_load <= data[10:0];
      end

      // channel 3
      10'h72 :
      begin
        ch3_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch3_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch3_glns_or_gps <= data[10];
        `endif
      end
      10'h74 : if (!wen & !csn) ch3_carr_nco_low <=  data[15:0];
      10'h76 : if (!wen & !csn) 
               begin
                 ch3_carr_nco     <= {data[12:0], ch3_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch3_carr_nco_sign <= data[15];
                 `endif
               end
      10'h78 : if (!wen & !csn) ch3_code_nco_low <=  data[15:0];
      10'h7A : if (!wen & !csn) ch3_code_nco     <= {data[11:0], ch3_code_nco_low};
      10'h7C : 
      begin
        ch3_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch3_code_slew <= data[10:0];
      end
      10'h7E : data_out <= ch3_i_early; //[Art]
      10'h80 : data_out <= ch3_q_early; //[Art]			 
      10'h82 : data_out <= ch3_i_prompt;//[Art]			 
      10'h84 : data_out <= ch3_q_prompt;//[Art]     		 
      10'h86 : data_out <= ch3_i_late;  //[Art]
      10'h88 : data_out <= ch3_q_late;  //[Art]
      10'h8A : data_out <= ch3_carrier_val[15:0];        // 16 bits low
      10'h8C : data_out <= ch3_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'h8E : data_out <= ch3_code_val[15:0];           // 16 bits low
      10'h90 : data_out <= {11'h0, ch3_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'h92 : data_out <= {5'h0, ch3_epoch};            // 11 bits //[Art]
      10'h94 : data_out <= {5'h0, ch3_epoch_check};      // 11 bits //[Art]
      10'h96 : 
      begin
        ch3_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch3_epoch_load <= data[10:0];
      end

      // channel 4
      10'h98 :
      begin
        ch4_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch4_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch4_glns_or_gps <= data[10];
        `endif
      end
      10'h9A : if (!wen & !csn) ch4_carr_nco_low <=  data[15:0];
      10'h9C : if (!wen & !csn) 
               begin
                 ch4_carr_nco     <= {data[12:0], ch4_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch4_carr_nco_sign <= data[15];
                 `endif
               end
      10'h9E : if (!wen & !csn) ch4_code_nco_low <=  data[15:0];
      10'hA0 : if (!wen & !csn) ch4_code_nco     <= {data[11:0], ch4_code_nco_low};
      10'hA2 : 
      begin
        ch4_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch4_code_slew <= data[10:0];
      end
      10'hA4 : data_out <= ch4_i_early; //[Art]
      10'hA6 : data_out <= ch4_q_early; //[Art]			 
      10'hA8 : data_out <= ch4_i_prompt;//[Art]			 
      10'hAA : data_out <= ch4_q_prompt;//[Art]     		 
      10'hAC : data_out <= ch4_i_late;  //[Art]
      10'hAE : data_out <= ch4_q_late;  //[Art]
      10'hB0 : data_out <= ch4_carrier_val[15:0];        // 16 bits low
      10'hB2 : data_out <= ch4_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'hB4 : data_out <= ch4_code_val[15:0];           // 16 bits low
      10'hB6 : data_out <= {11'h0, ch4_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'hB8 : data_out <= {5'h0, ch4_epoch};            // 11 bits //[Art]
      10'hBA : data_out <= {5'h0, ch4_epoch_check};      // 11 bits //[Art]
      10'hBC : 
      begin
        ch4_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch4_epoch_load <= data[10:0];
      end

      // channel 5
      10'hBE :
      begin
        ch5_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch5_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch5_glns_or_gps <= data[10];
        `endif
      end
      10'hC0 : if (!wen & !csn) ch5_carr_nco_low <=  data[15:0];
      10'hC2 : if (!wen & !csn) 
               begin
                 ch5_carr_nco     <= {data[12:0], ch5_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch5_carr_nco_sign <= data[15];
                 `endif
               end
      10'hC4 : if (!wen & !csn) ch5_code_nco_low <=  data[15:0];
      10'hC6 : if (!wen & !csn) ch5_code_nco     <= {data[11:0], ch5_code_nco_low};
      10'hC8 : 
      begin
        ch5_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch5_code_slew <= data[10:0];
      end
      10'hCA : data_out <= ch5_i_early; //[Art]
      10'hCC : data_out <= ch5_q_early; //[Art]			 
      10'hCE : data_out <= ch5_i_prompt;//[Art]			 
      10'hD0 : data_out <= ch5_q_prompt;//[Art]     		 
      10'hD2 : data_out <= ch5_i_late;  //[Art]
      10'hD4 : data_out <= ch5_q_late;  //[Art]
      10'hD6 : data_out <= ch5_carrier_val[15:0];        // 16 bits low
      10'hD8 : data_out <= ch5_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'hDA : data_out <= ch5_code_val[15:0];           // 16 bits low
      10'hDC : data_out <= {11'h0, ch5_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'hDE : data_out <= {5'h0, ch5_epoch};            // 11 bits //[Art]
      10'hE0 : data_out <= {5'h0, ch5_epoch_check};      // 11 bits //[Art]
      10'hE2 : 
      begin
        ch5_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch5_epoch_load <= data[10:0];
      end

      `ifndef ENABLE_LIMITED_VERSION
      // channel 6
      10'hE4 :
      begin
        ch6_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch6_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch6_glns_or_gps <= data[10];
        `endif
      end
      10'hE6 : if (!wen & !csn) ch6_carr_nco_low <=  data[15:0];
      10'hE8 : if (!wen & !csn) 
               begin
                 ch6_carr_nco     <= {data[12:0], ch6_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch6_carr_nco_sign <= data[15];
                 `endif
               end
      10'hEA : if (!wen & !csn) ch6_code_nco_low <=  data[15:0];
      10'hEC : if (!wen & !csn) ch6_code_nco     <= {data[11:0], ch6_code_nco_low};
      10'hEE : 
      begin
        ch6_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch6_code_slew <= data[10:0];
      end
      10'hF0 : data_out <= ch6_i_early; //[Art]
      10'hF2 : data_out <= ch6_q_early; //[Art]			 
      10'hF4 : data_out <= ch6_i_prompt;//[Art]			 
      10'hF6 : data_out <= ch6_q_prompt;//[Art]     		 
      10'hF8 : data_out <= ch6_i_late;  //[Art]
      10'hFA : data_out <= ch6_q_late;  //[Art]
      10'hFC : data_out <= ch6_carrier_val[15:0];        // 16 bits low
      10'hFE : data_out <= ch6_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'h100: data_out <= ch6_code_val[15:0];           // 16 bits low
      10'h102: data_out <= {11'h0, ch6_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'h104: data_out <= {5'h0, ch6_epoch};            // 11 bits //[Art]
      10'h106: data_out <= {5'h0, ch6_epoch_check};      // 11 bits //[Art]
      10'h108: 
      begin
        ch6_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch6_epoch_load <= data[10:0];
      end

      // channel 7
      10'h10A:
      begin
        ch7_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch7_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch7_glns_or_gps <= data[10];
        `endif
      end
      10'h10C: if (!wen & !csn) ch7_carr_nco_low <=  data[15:0];
      10'h10E: if (!wen & !csn) 
               begin
                 ch7_carr_nco     <= {data[12:0], ch7_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch7_carr_nco_sign <= data[15];
                 `endif
               end
      10'h110: if (!wen & !csn) ch7_code_nco_low <=  data[15:0];
      10'h112: if (!wen & !csn) ch7_code_nco     <= {data[11:0], ch7_code_nco_low};
      10'h114: 
      begin
        ch7_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch7_code_slew <= data[10:0];
      end
      10'h116: data_out <= ch7_i_early; //[Art]
      10'h118: data_out <= ch7_q_early; //[Art]			 
      10'h11A: data_out <= ch7_i_prompt;//[Art]			 
      10'h11C: data_out <= ch7_q_prompt;//[Art]     		 
      10'h11E: data_out <= ch7_i_late;  //[Art]
      10'h120: data_out <= ch7_q_late;  //[Art]
      10'h122: data_out <= ch7_carrier_val[15:0];        // 16 bits low
      10'h124: data_out <= ch7_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'h126: data_out <= ch7_code_val[15:0];           // 16 bits low
      10'h128: data_out <= {11'h0, ch7_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'h12A: data_out <= {5'h0, ch7_epoch};            // 11 bits //[Art]
      10'h12C: data_out <= {5'h0, ch7_epoch_check};      // 11 bits //[Art]
      10'h12E: 
      begin
        ch7_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch7_epoch_load <= data[10:0];
      end

      // channel 8
      10'h130:
      begin
        ch8_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch8_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch8_glns_or_gps <= data[10];
        `endif
      end
      10'h132: if (!wen & !csn) ch8_carr_nco_low <=  data[15:0];
      10'h134: if (!wen & !csn) 
               begin
                 ch8_carr_nco     <= {data[12:0], ch8_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch8_carr_nco_sign <= data[15];
                 `endif
               end
      10'h136: if (!wen & !csn) ch8_code_nco_low <=  data[15:0];
      10'h138: if (!wen & !csn) ch8_code_nco     <= {data[11:0], ch8_code_nco_low};
      10'h13A: 
      begin
        ch8_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch8_code_slew <= data[10:0];
      end
      10'h13C: data_out <= ch8_i_early; //[Art]
      10'h13E: data_out <= ch8_q_early; //[Art]			 
      10'h140: data_out <= ch8_i_prompt;//[Art]			 
      10'h142: data_out <= ch8_q_prompt;//[Art]     		 
      10'h144: data_out <= ch8_i_late;  //[Art]
      10'h146: data_out <= ch8_q_late;  //[Art]
      10'h148: data_out <= ch8_carrier_val[15:0];        // 16 bits low
      10'h14A: data_out <= ch8_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'h14C: data_out <= ch8_code_val[15:0];           // 16 bits low
      10'h14E: data_out <= {11'h0, ch8_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'h150: data_out <= {5'h0, ch8_epoch};            // 11 bits //[Art]
      10'h152: data_out <= {5'h0, ch8_epoch_check};      // 11 bits //[Art]
      10'h154: 
      begin
        ch8_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch8_epoch_load <= data[10:0];
      end

      // channel 9
      10'h156:
      begin
        ch9_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch9_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch9_glns_or_gps <= data[10];
        `endif
      end
      10'h158: if (!wen & !csn) ch9_carr_nco_low <=  data[15:0];
      10'h15A: if (!wen & !csn) 
               begin
                 ch9_carr_nco     <= {data[12:0], ch9_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch9_carr_nco_sign <= data[15];
                 `endif
               end
      10'h15C: if (!wen & !csn) ch9_code_nco_low <=  data[15:0];
      10'h15E: if (!wen & !csn) ch9_code_nco     <= {data[11:0], ch9_code_nco_low};
      10'h160: 
      begin
        ch9_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch9_code_slew <= data[10:0];
      end
      10'h162: data_out <= ch9_i_early; //[Art]
      10'h164: data_out <= ch9_q_early; //[Art]			 
      10'h166: data_out <= ch9_i_prompt;//[Art]			 
      10'h168: data_out <= ch9_q_prompt;//[Art]     		 
      10'h16A: data_out <= ch9_i_late;  //[Art]
      10'h16C: data_out <= ch9_q_late;  //[Art]
      10'h16E: data_out <= ch9_carrier_val[15:0];        // 16 bits low
      10'h170: data_out <= ch9_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'h172: data_out <= ch9_code_val[15:0];           // 16 bits low
      10'h174: data_out <= {11'h0, ch9_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'h176: data_out <= {5'h0, ch9_epoch};            // 11 bits //[Art]
      10'h178: data_out <= {5'h0, ch9_epoch_check};      // 11 bits //[Art]
      10'h17A: 
      begin
        ch9_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch9_epoch_load <= data[10:0];
      end

      `ifndef ENABLE_LIMITED_VERSION_2
      // channel 10
      10'h17C:
      begin
        ch10_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch10_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch10_glns_or_gps <= data[10];
        `endif
      end
      10'h17E: if (!wen & !csn) ch10_carr_nco_low <=  data[15:0];
      10'h180: if (!wen & !csn) 
               begin
                 ch10_carr_nco     <= {data[12:0], ch10_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch10_carr_nco_sign <= data[15];
                 `endif
               end
      10'h182: if (!wen & !csn) ch10_code_nco_low <=  data[15:0];
      10'h184: if (!wen & !csn) ch10_code_nco     <= {data[11:0], ch10_code_nco_low};
      10'h186: 
      begin
        ch10_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch10_code_slew <= data[10:0];
      end
      10'h188: data_out <= ch10_i_early; //[Art]
      10'h18A: data_out <= ch10_q_early; //[Art]			 
      10'h18C: data_out <= ch10_i_prompt;//[Art]			 
      10'h18E: data_out <= ch10_q_prompt;//[Art]     		 
      10'h190: data_out <= ch10_i_late;  //[Art]
      10'h192: data_out <= ch10_q_late;  //[Art]
      10'h194: data_out <= ch10_carrier_val[15:0];        // 16 bits low
      10'h196: data_out <= ch10_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'h198: data_out <= ch10_code_val[15:0];           // 16 bits low
      10'h19A: data_out <= {11'h0, ch10_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'h19C: data_out <= {5'h0, ch10_epoch};            // 11 bits //[Art]
      10'h19E: data_out <= {5'h0, ch10_epoch_check};      // 11 bits //[Art]
      10'h1A0: 
      begin
        ch10_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch10_epoch_load <= data[10:0];
      end

      // channel 11
      10'h1A2:
      begin
        ch11_prn_key_enable <= !wen & !csn;
        if (!wen & !csn) ch11_prn_key <= data[9:0];
        `ifdef ENABLE_GLONASS
        if (!wen & !csn) ch11_glns_or_gps <= data[10];
        `endif
      end
      10'h1A4: if (!wen & !csn) ch11_carr_nco_low <=  data[15:0];
      10'h1A6: if (!wen & !csn) 
               begin
                 ch11_carr_nco     <= {data[12:0], ch11_carr_nco_low};
                 `ifdef ENABLE_IQ_PROCESSING
                 ch11_carr_nco_sign <= data[15];
                 `endif
               end
      10'h1A8: if (!wen & !csn) ch11_code_nco_low <=  data[15:0];
      10'h1AA: if (!wen & !csn) ch11_code_nco     <= {data[11:0], ch11_code_nco_low};
      10'h1AC: 
      begin
        ch11_slew_enable <= !wen & !csn;
        if (!wen & !csn) ch11_code_slew <= data[10:0];
      end
      10'h1AE: data_out <= ch11_i_early; //[Art]
      10'h1B0: data_out <= ch11_q_early; //[Art]			 
      10'h1B2: data_out <= ch11_i_prompt;//[Art]			 
      10'h1B4: data_out <= ch11_q_prompt;//[Art]     		 
      10'h1B6: data_out <= ch11_i_late;  //[Art]
      10'h1B8: data_out <= ch11_q_late;  //[Art]
      10'h1BA: data_out <= ch11_carrier_val[15:0];        // 16 bits low
      10'h1BC: data_out <= ch11_carrier_val[31:16];       // 16 bits high (total 32 bits)
      10'h1BE: data_out <= ch11_code_val[15:0];           // 16 bits low
      10'h1C0: data_out <= {11'h0, ch11_code_val[20:16]}; // 5 bits high (total 21 bits)
      10'h1C2: data_out <= {5'h0, ch11_epoch};            // 11 bits //[Art]
      10'h1C4: data_out <= {5'h0, ch11_epoch_check};      // 11 bits //[Art]
      10'h1C6: 
      begin
        ch11_epoch_enable <= !wen & !csn;
        if (!wen & !csn) ch11_epoch_load <= data[10:0];
      end
      `endif
      `endif
      `endif

		//status address and new_data address must be "very differenet".
		//For example 10'h230 for status and 10'h232 for new_data don't fit!!!
		//Because due to some unknown reasons control mcu (lpc2478) generates address
		//in a strange manner. And with the mentioned addresses I got two pulses
		//when reading status register (status_read pulse and new_data_pulse).
		//changing addresses to "more different" has solved this problem...
      
      // status
      10'h232: 
      begin // get status and pulse status_flag to clear status
        data_out    <= {14'h0, status}; // only 2 status bits, therefore need to pad 30ms bits
      end
      10'h246: 
      begin // get new_data
        data_out <= {4'h0,new_data};    // one new_data bit per channel, need to pad other bits
      end
      10'h236: 
      begin // tic count read low bits
        data_out <= tic_count[15:0];           // 16 low bits of TIC count
      end
      10'h238: 
      begin // tic count read high bits
        data_out <= {8'h0,tic_count[23:16]};   // 8 high bits of TIC count
      end
      10'h23A: 
      begin // accum count read low bits
        data_out <= accum_count[15:0];         // 16 low bits of accum count
      end
      10'h23C: 
      begin // accum count read high bits
        data_out <= {8'h0,accum_count[23:16]}; // 8 high bits of accum count
      end

      // control
      10'h222: if (!wen & !csn) prog_tic[15:0]        <= data[15:0]; // program TIC_low
      10'h224: if (!wen & !csn) prog_tic[23:16]       <= data[7:0];  // program TIC_high
      10'h226: if (!wen & !csn) prog_accum_int[15:0]  <= data[15:0]; // program ACCUM_INT_low
      10'h228: if (!wen & !csn) prog_accum_int[23:16] <= data[7:0];  // program ACCUM_INT_high

      // test memory interface:
      10'h300 : if (!wen & !csn) test_memory[0] <= data[15:0];
      10'h302 : if (!wen & !csn) test_memory[1] <= data[15:0];
      10'h304 : if (!wen & !csn) test_memory[2] <= data[15:0];
      10'h306 : if (!wen & !csn) test_memory[3] <= data[15:0];
      10'h308 : if (!wen & !csn) test_memory[4] <= data[15:0];
      10'h30A : if (!wen & !csn) test_memory[5] <= data[15:0];
      10'h30C : if (!wen & !csn) test_memory[6] <= data[15:0];
      10'h30E : if (!wen & !csn) test_memory[7] <= data[15:0];

      10'h310 : data_out <= test_memory[0];
      10'h312 : data_out <= test_memory[1];
      10'h314 : data_out <= test_memory[2];
      10'h316 : data_out <= test_memory[3];
      10'h318 : data_out <= test_memory[4];
      10'h31A : data_out <= test_memory[5];
      10'h31C : data_out <= test_memory[6];
      10'h31E : data_out <= test_memory[7];
      // test memory interface - END.
       
      default : data_out <= 16'b0000000000000000;

    endcase // case(address)
  end

  //Add condiotional synthesis here.
  `ifdef ENABLE_VERILATOR_SIMULATION
  initial begin //For testing only;
    new_data        = 12'b000000000000;
    new_data_miss   = 12'b000000000000;

    status          = 2'b00;
    status_miss     = 2'b00;
  end
  `endif
  //Add condiotional synthesis here - END.
  
  wire sw_rst        = ( (address == 10'h220) && ((!wen))) ? 1'b1 : 1'b0;
  wire new_data_read = ( (address == 10'h246) && ((!oen))) ? 1'b1 : 1'b0;
  wire status_read   = ( (address == 10'h232) && ((!oen))) ? 1'b1 : 1'b0;
  assign rstn = hw_rstn & ~sw_rst;

  /* FSM1 for new_data_read processing */
  reg [1:0] ndr_state;
  
  parameter NO_NEW_DATA_READ_STATE     = 2'd0;
  parameter NEW_DATA_READ_STATE        = 2'd1;
  parameter NEW_DATA_READ_AFTER1_STATE = 2'd2;
  

  always @(posedge clk)
  begin
    if(!rstn)
    begin
      ndr_state     <= NO_NEW_DATA_READ_STATE;
      new_data      <= 12'b000000000000;
      new_data_miss <= 12'b000000000000;
    end
    else
    begin
      case(ndr_state)
        
        NO_NEW_DATA_READ_STATE:
        begin
          if (new_data_read)
          begin
            ndr_state <= NEW_DATA_READ_STATE;

            if (ch0_dump)  new_data_miss[0]  <= 1'b1;
            `ifndef ENABLE_SINGLE_CHANNEL
            if (ch1_dump)  new_data_miss[1]  <= 1'b1;
            if (ch2_dump)  new_data_miss[2]  <= 1'b1;
            if (ch3_dump)  new_data_miss[3]  <= 1'b1;
            if (ch4_dump)  new_data_miss[4]  <= 1'b1;
            if (ch5_dump)  new_data_miss[5]  <= 1'b1;
            `ifndef ENABLE_LIMITED_VERSION
            if (ch6_dump)  new_data_miss[6]  <= 1'b1;
            if (ch7_dump)  new_data_miss[7]  <= 1'b1;
            if (ch8_dump)  new_data_miss[8]  <= 1'b1;
            if (ch9_dump)  new_data_miss[9]  <= 1'b1;
				`ifndef ENABLE_LIMITED_VERSION_2
            if (ch10_dump) new_data_miss[10] <= 1'b1;
            if (ch11_dump) new_data_miss[11] <= 1'b1;
            `endif
            `endif
            `endif
          end
          else
          begin
            if (ch0_dump)  new_data[0]  <= 1'b1;
            `ifndef ENABLE_SINGLE_CHANNEL
            if (ch1_dump)  new_data[1]  <= 1'b1;
            if (ch2_dump)  new_data[2]  <= 1'b1;
            if (ch3_dump)  new_data[3]  <= 1'b1;
            if (ch4_dump)  new_data[4]  <= 1'b1;
            if (ch5_dump)  new_data[5]  <= 1'b1;
            `ifndef ENABLE_LIMITED_VERSION
            if (ch6_dump)  new_data[6]  <= 1'b1;
            if (ch7_dump)  new_data[7]  <= 1'b1;
            if (ch8_dump)  new_data[8]  <= 1'b1;
            if (ch9_dump)  new_data[9]  <= 1'b1;
            `ifndef ENABLE_LIMITED_VERSION_2
            if (ch10_dump) new_data[10] <= 1'b1;
            if (ch11_dump) new_data[11] <= 1'b1;
            `endif
            `endif
            `endif
            
            new_data_miss <= 12'b000000000000;
          end
        end
        
        NEW_DATA_READ_STATE:
        begin
          if (!new_data_read) ndr_state <= NEW_DATA_READ_AFTER1_STATE;
          
          if (ch0_dump)  new_data_miss[0]  <= 1'b1;
          `ifndef ENABLE_SINGLE_CHANNEL
          if (ch1_dump)  new_data_miss[1]  <= 1'b1;
          if (ch2_dump)  new_data_miss[2]  <= 1'b1;
          if (ch3_dump)  new_data_miss[3]  <= 1'b1;
          if (ch4_dump)  new_data_miss[4]  <= 1'b1;
          if (ch5_dump)  new_data_miss[5]  <= 1'b1;
          `ifndef ENABLE_LIMITED_VERSION
          if (ch6_dump)  new_data_miss[6]  <= 1'b1;
          if (ch7_dump)  new_data_miss[7]  <= 1'b1;
          if (ch8_dump)  new_data_miss[8]  <= 1'b1;
          if (ch9_dump)  new_data_miss[9]  <= 1'b1;
          `ifndef ENABLE_LIMITED_VERSION_2
          if (ch10_dump) new_data_miss[10] <= 1'b1;
          if (ch11_dump) new_data_miss[11] <= 1'b1;
          `endif
          `endif
          `endif
        end
        
        
        NEW_DATA_READ_AFTER1_STATE:
        begin
          ndr_state <= NO_NEW_DATA_READ_STATE;
          
          if (ch0_dump  | new_data_miss[0])  new_data[0]  <= 1'b1; else new_data[0]  <= 1'b0;
          `ifndef ENABLE_SINGLE_CHANNEL
          if (ch1_dump  | new_data_miss[1])  new_data[1]  <= 1'b1; else new_data[1]  <= 1'b0;
          if (ch2_dump  | new_data_miss[2])  new_data[2]  <= 1'b1; else new_data[2]  <= 1'b0;
          if (ch3_dump  | new_data_miss[3])  new_data[3]  <= 1'b1; else new_data[3]  <= 1'b0;
          if (ch4_dump  | new_data_miss[4])  new_data[4]  <= 1'b1; else new_data[4]  <= 1'b0;
          if (ch5_dump  | new_data_miss[5])  new_data[5]  <= 1'b1; else new_data[5]  <= 1'b0;
          `ifndef ENABLE_LIMITED_VERSION
          if (ch6_dump  | new_data_miss[6])  new_data[6]  <= 1'b1; else new_data[6]  <= 1'b0;
          if (ch7_dump  | new_data_miss[7])  new_data[7]  <= 1'b1; else new_data[7]  <= 1'b0;
          if (ch8_dump  | new_data_miss[8])  new_data[8]  <= 1'b1; else new_data[8]  <= 1'b0;
          if (ch9_dump  | new_data_miss[9])  new_data[9]  <= 1'b1; else new_data[9]  <= 1'b0;
          `ifndef ENABLE_LIMITED_VERSION_2
          if (ch10_dump | new_data_miss[10]) new_data[10] <= 1'b1; else new_data[10]  <= 1'b0;
          if (ch11_dump | new_data_miss[11]) new_data[11] <= 1'b1; else new_data[11]  <= 1'b0;
          `endif
          `endif
          `endif
        end
        
        default:
        begin
          ndr_state <= NO_NEW_DATA_READ_STATE;
        end
        		  
      endcase
    end
    
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
  
  parameter NO_STATUS_READ_STATE	    = 2'd0;
  parameter STATUS_READ_STATE		    = 2'd1;
  parameter STATUS_READ_AFTER1_STATE = 2'd2;
  
  
  always @(posedge clk)
  begin
    if (!rstn)
    begin
      sr_state    <= NO_STATUS_READ_STATE;
      status      <= 2'b00;
      status_miss <= 2'b00;
    end
    else
    begin
      case(sr_state)
        
        NO_STATUS_READ_STATE:
        begin
          if (status_read)
          begin
            sr_state <= STATUS_READ_STATE;
            
            if (tic_enable)     status_miss[0] <= 1'b1;
            if (accum_enable_s) status_miss[1] <= 1'b1;
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
          if (!status_read) sr_state <= STATUS_READ_AFTER1_STATE;

          if (tic_enable)     status_miss[0] <= 1'b1;
          if (accum_enable_s) status_miss[1] <= 1'b1;
        end
        
        STATUS_READ_AFTER1_STATE:
        begin
          sr_state <= NO_STATUS_READ_STATE;
          
          if (tic_enable     | status_miss[0]) status[0] <= 1'b1; else status[0] <= 1'b0;
          if (accum_enable_s | status_miss[1]) status[1] <= 1'b1; else status[1] <= 1'b0;
        end
        
        default:
        begin
          sr_state <= NO_STATUS_READ_STATE;
        end
        
      endcase
    end
  end
  

  assign accum_int = status[1];

  /* FSM2 END */

  /*Async memory databus routines:*/
  always @(posedge clk)
  begin
    if(!rstn)
    begin
      csn_1 <= 1'b1;
      csn   <= 1'b1;
      wen_1 <= 1'b1;
      wen   <= 1'b1;
      oen_1 <= 1'b1;
      oen   <= 1'b1;
      
      // Had to pass address through flip-flops too. Otherwise errors happen during 
      // bus read/write... (some problems in verilator with these two lines...)
      `ifndef ENABLE_VERILATOR_SIMULATION
      address_1 <= 10'b0000000000;
      address   <= 10'b0000000000;
      `endif
    end
    else
    begin
      csn_1 <= csn_a;
      csn   <= csn_1;
      wen_1 <= wen_a;
      wen   <= wen_1;
      oen_1 <= oen_a;
      oen   <= oen_1;
      
      // Had to pass address through flip-flops too. Otherwise errors happen during 
      // bus read/write... (some problems in verilator with these two lines...)
      `ifndef ENABLE_VERILATOR_SIMULATION
      address_1 <= address_a;
      address   <= address_1;
      `endif
    end
  end
  `ifdef ENABLE_VERILATOR_SIMULATION
  assign address   = address_a;
  assign address_1 = address_a;
  `endif
  /*Async memory databus routines - END*/

  `ifndef ENABLE_VERILATOR_SIMULATION
  assign data = (!oen) ? data_out : 16'hzzzz;
  `endif  
  
  //Local clock generation:
  `ifndef ENABLE_VERILATOR_SIMULATION
  wire sys0_clk_dcm;
  //wire clk;//WTF?!

  DCM_SP #(
    .CLKDV_DIVIDE(2.0),		// 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
    
    .CLKFX_DIVIDE(1),		// 1 to 32
    .CLKFX_MULTIPLY(5),		// 2 to 32
    
    .CLKIN_DIVIDE_BY_2("FALSE"),
    .CLKIN_PERIOD(12.5),
    .CLKOUT_PHASE_SHIFT("NONE"),
    .CLK_FEEDBACK("NONE"),
    .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
    .DUTY_CYCLE_CORRECTION("TRUE"),
    .PHASE_SHIFT(0),
    .STARTUP_WAIT("TRUE")
  ) clkgen0_sys (
    .CLK0(),
    .CLK90(),
    .CLK180(),
    .CLK270(),
    
    .CLK2X(),
    .CLK2X180(),
    
    .CLKDV(),
    .CLKFX(sys0_clk_dcm),
    .CLKFX180(),
    .LOCKED(),
    .CLKFB(),
    .CLKIN(extclk),
    .RST(1'b0),
    .PSEN(1'b0)
  );
  BUFG b0(
    .I(sys0_clk_dcm),
    .O(clk) //80MHz clock generated from 16 MHz reference
  );
  `endif
  //Local clock generation - END.
  
  //DEBUG SIGNALS ASSIGNMENTS:
  `ifdef ENABLE_DEBUG_SIGNALS_OUTPUT
  assign test_point_01 = status_read;
  assign test_point_02 = new_data[0];
  assign test_point_03 = status[1];
  assign test_point_04 = sw_rst;
  assign test_point_05 = new_data_read;
  `endif
  //DEBUG SIGNALS ASSIGNMENTS - END.
  
endmodule // gps_baseband
 
