//                              -*- Mode: Verilog -*-
// Filename        : tracking_channel.v
// Description     : Wire the correlator block together.
//                   2 carrier_mixers
//                   1 carrier_nco
//                   1 code_nco
//                   1 code_gen
//                   1 epoch_counter
//                   6 accumulators

// Author          : Peter Mumford, UNSW 2005
// Author          : Gavrilov Artyom, gnss-sdr.com, 2012 (iq-processing upgrade).

/*
	Copyright (C) 2007  Peter Mumford

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

`include "namuro_gnss_setup.v"

module tracking_channel (clk, rstn, accum_sample_enable,
                         if_sign, if_mag,
                         `ifdef ENABLE_IQ_PROCESSING
                          if_sign_q, if_mag_q,
                         `endif
                         pre_tic_enable, tic_enable,
                         `ifdef ENABLE_IQ_PROCESSING
                         carr_nco_fc_sign,
                         `endif
                         carr_nco_fc,
                         code_nco_fc,
                         `ifdef ENABLE_GLONASS
                         glns_or_gps,
                         `endif
                         prn_key,
                         prn_key_enable,
                         code_slew, slew_enable, epoch_enable,
                         dump,
                         i_early,q_early,i_prompt,q_prompt,i_late,q_late,
                         carrier_val,code_val,epoch_load,epoch,epoch_check,
                         test_point_01, test_point_02, test_point_03);

  input clk, rstn, accum_sample_enable, pre_tic_enable, tic_enable, prn_key_enable, slew_enable, epoch_enable;
  input if_sign, if_mag;
  `ifdef ENABLE_IQ_PROCESSING
  input if_sign_q, if_mag_q; //[Art]
  input carr_nco_fc_sign;    //[Art]
  `endif
  input [28:0] carr_nco_fc;
  input [27:0] code_nco_fc;
  `ifdef ENABLE_GLONASS
  input glns_or_gps;
  `endif
  input [9:0]  prn_key;
  input [10:0] code_slew;
  input [10:0] epoch_load;

  //output [31:0] i_early,q_early,i_prompt,q_prompt,i_late,q_late;
  output [15:0] i_early,q_early,i_prompt,q_prompt,i_late,q_late;
  output [31:0] carrier_val;
  output [10:0] epoch, epoch_check;
  output [20:0] code_val;
  output        dump;
   
  output test_point_01, test_point_02, test_point_03;
   
  wire carrier_i_mag,  carrier_q_mag;
  wire hc_enable, dump_enable;
  wire early_code, prompt_code, late_code;
  `ifndef ENABLE_IQ_PROCESSING
  wire carrier_i_sign, carrier_q_sign;
  wire       mix_i_sign, mix_q_sign;
  wire [2:0] mix_i_mag,  mix_q_mag;
  `else
  wire       mix_ii_sign, mix_qq_sign, mix_iq_sign, mix_qi_sign; //[Art] We have four multipliers!
  wire [2:0] mix_ii_mag,  mix_qq_mag,  mix_iq_mag,  mix_qi_mag;  //[Art] In case of IQ-processing!
  wire carrier_i_sign_tmp, carrier_q_sign_tmp;                   //[Art] These sign come from carrier NCO!
                                                                 //[Art] They must be corrected by the 
                                                                 //[Art] sign of the NCO frequency!
  `endif
   
  assign dump = dump_enable;
   

  `ifndef ENABLE_IQ_PROCESSING
  // carrier mixers -----------------------------------------------------------
  carrier_mixer i_cos (.if_sign(if_sign), .if_mag(if_mag), // raw data input
                       .carrier_sign(carrier_i_sign), .carrier_mag(carrier_i_mag), // carrier nco inputs
                       .mix_sign(mix_i_sign), .mix_mag(mix_i_mag) // outputs
                      );
   
  carrier_mixer q_sin (.if_sign(if_sign), .if_mag(if_mag), // raw data input
                       .carrier_sign(carrier_q_sign), .carrier_mag(carrier_q_mag), // carrier nco inputs
                       .mix_sign(mix_q_sign), .mix_mag(mix_q_mag) // outputs
                      );
  // carrier nco --------------------------------------------------------------
  carrier_nco carrnco (.clk(clk), .rstn(rstn), .tic_enable(tic_enable),
                       .f_control(carr_nco_fc),
                       .carrier_val(carrier_val),
                       .i_sign(carrier_i_sign), .i_mag(carrier_i_mag),
                       .q_sign(carrier_q_sign), .q_mag(carrier_q_mag)
                      );
   // code nco -----------------------------------------------------------------
  code_nco codenco    (.clk(clk), .rstn(rstn), .tic_enable(pre_tic_enable),
                       .f_control(code_nco_fc),
                       .hc_enable(hc_enable), .code_nco_phase(code_val[9:0])
                      );
  // code gen -----------------------------------------------------------------
  code_gen codegen    (.clk(clk), .rstn(rstn), .tic_enable(tic_enable),
                       .hc_enable(hc_enable), 
                       `ifdef ENABLE_GLONASS
                       .glns_or_gps(glns_or_gps),
                       `endif
                       .prn_key_enable(prn_key_enable),
                       .prn_key(prn_key), .code_slew(code_slew), .slew_enable(slew_enable),
                       .dump_enable(dump_enable), .code_phase(code_val[20:10]),
                       .early(early_code), .prompt(prompt_code), .late(late_code)
                      );
  // epoch counter ------------------------------------------------------------
  epoch_counter epc   (.clk(clk), .rstn(rstn),
                       .tic_enable(tic_enable), .dump_enable(dump_enable),
                       .epoch_enable(epoch_enable), .epoch_load(epoch_load),
                       .epoch(epoch), .epoch_check(epoch_check)
                      );
  // accumulators -------------------------------------------------------------
  // in-phase early
  accumulator ie      (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(early_code),
                       .carrier_mix_sign(mix_i_sign), .carrier_mix_mag(mix_i_mag),
                       .dump_enable(dump_enable), .accumulation(i_early)
                      );
  // in-phase prompt
  accumulator ip      (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(prompt_code),
                       .carrier_mix_sign(mix_i_sign), .carrier_mix_mag(mix_i_mag),
                       .dump_enable(dump_enable), .accumulation(i_prompt)
                      );
  // in-phase late
  accumulator il      (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(late_code),
                       .carrier_mix_sign(mix_i_sign), .carrier_mix_mag(mix_i_mag),
                       .dump_enable(dump_enable), .accumulation(i_late)
                      );
  // quadrature-phase early
  accumulator qe      (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(early_code),
                       .carrier_mix_sign(mix_q_sign), .carrier_mix_mag(mix_q_mag),
                       .dump_enable(dump_enable), .accumulation(q_early)
                      );
  // quadrature-phase prompt
  accumulator qp      (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(prompt_code),
                       .carrier_mix_sign(mix_q_sign), .carrier_mix_mag(mix_q_mag),
                       .dump_enable(dump_enable), .accumulation(q_prompt)
                       );
  // quadrature-phase late
  accumulator ql      (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(late_code),
                       .carrier_mix_sign(mix_q_sign), .carrier_mix_mag(mix_q_mag),
                       .dump_enable(dump_enable), .accumulation(q_late)
                      );
  //-------------------------------------------------------------------------
  `else
  // carrier mixers -----------------------------------------------------------
  // For iq-processing 4 mixers are used instead of 2 (to make multiplication of complex numbers).
  carrier_mixer ii (.if_sign(if_sign), .if_mag(if_mag), // raw data input
                    .carrier_sign(carrier_i_sign), .carrier_mag(carrier_i_mag), // carrier nco inputs
                    .mix_sign(mix_ii_sign), .mix_mag(mix_ii_mag) // outputs
                   );
   
  carrier_mixer qq (.if_sign(if_sign_q), .if_mag(if_mag_q), // raw data input
                    .carrier_sign(carrier_q_sign), .carrier_mag(carrier_q_mag), // carrier nco inputs
                    .mix_sign(mix_qq_sign), .mix_mag(mix_qq_mag) // outputs
                   );

  carrier_mixer qi (.if_sign(if_sign_q), .if_mag(if_mag_q), // raw data input
                    .carrier_sign(carrier_i_sign), .carrier_mag(carrier_i_mag), // carrier nco inputs
                    .mix_sign(mix_qi_sign), .mix_mag(mix_qi_mag) // outputs
                   );
   
  carrier_mixer iq (.if_sign(if_sign), .if_mag(if_mag), // raw data input
                    .carrier_sign(carrier_q_sign), .carrier_mag(carrier_q_mag), // carrier nco inputs
                    .mix_sign(mix_iq_sign), .mix_mag(mix_iq_mag) // outputs
                   );
  // carrier nco --------------------------------------------------------------
  carrier_nco carrnco (.clk(clk), .rstn(rstn), .tic_enable(tic_enable),
                       .f_control(carr_nco_fc),
                       .carrier_val(carrier_val),
                       .i_sign(carrier_i_sign_tmp), .i_mag(carrier_i_mag),
                       .q_sign(carrier_q_sign_tmp), .q_mag(carrier_q_mag)
                      );
  // The sign of the NCO frequency is taken in account in such a way that
  // sign of the mixer output is changed for sin wave and is kept for cosine.
  /*wire*/ assign carrier_i_sign = (~(carrier_i_sign_tmp ^ carr_nco_fc_sign));
  /*wire*/ assign carrier_q_sign = carrier_q_sign_tmp;
  // code nco -----------------------------------------------------------------
  code_nco codenco    (.clk(clk), .rstn(rstn), .tic_enable(pre_tic_enable),
                       .f_control(code_nco_fc),
                       .hc_enable(hc_enable), .code_nco_phase(code_val[9:0])
                      );
  // code gen -----------------------------------------------------------------
  code_gen codegen    (.clk(clk), .rstn(rstn), .tic_enable(tic_enable),
                       .hc_enable(hc_enable), 
                       `ifdef ENABLE_GLONASS
                       .glns_or_gps(glns_or_gps),
                       `endif
                       .prn_key_enable(prn_key_enable),
                       .prn_key(prn_key), .code_slew(code_slew), .slew_enable(slew_enable),
                       .dump_enable(dump_enable), .code_phase(code_val[20:10]),
                       .early(early_code), .prompt(prompt_code), .late(late_code)
                      );
  // epoch counter ------------------------------------------------------------
  epoch_counter epc   (.clk(clk), .rstn(rstn),
                       .tic_enable(tic_enable), .dump_enable(dump_enable),
                       .epoch_enable(epoch_enable), .epoch_load(epoch_load),
                       .epoch(epoch), .epoch_check(epoch_check)
                      );
  // accumulators -------------------------------------------------------------
  // in-phase early
  accumulator_two_inputs ie (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(early_code),
                             .carrier_mix1_sign(mix_ii_sign), .carrier_mix1_mag(mix_ii_mag),
                             .carrier_mix2_sign(~mix_qq_sign), .carrier_mix2_mag(mix_qq_mag),
                             .dump_enable(dump_enable), .accumulation(i_early)
                            );
  // in-phase prompt
  accumulator_two_inputs ip (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(prompt_code),
                             .carrier_mix1_sign(mix_ii_sign), .carrier_mix1_mag(mix_ii_mag),
                             .carrier_mix2_sign(~mix_qq_sign), .carrier_mix2_mag(mix_qq_mag),
                             .dump_enable(dump_enable), .accumulation(i_prompt)
                            );
  // in-phase late
  accumulator_two_inputs il (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(late_code),
                             .carrier_mix1_sign(mix_ii_sign), .carrier_mix1_mag(mix_ii_mag),
                             .carrier_mix2_sign(~mix_qq_sign), .carrier_mix2_mag(mix_qq_mag),
                             .dump_enable(dump_enable), .accumulation(i_late)
                            );
  // quadrature-phase early
  accumulator_two_inputs qe (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(early_code),
                             .carrier_mix1_sign(mix_qi_sign), .carrier_mix1_mag(mix_qi_mag),
                             .carrier_mix2_sign(mix_iq_sign), .carrier_mix2_mag(mix_iq_mag),
                             .dump_enable(dump_enable), .accumulation(q_early)
                            );
  // quadrature-phase prompt
  accumulator_two_inputs qp (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(prompt_code),
                             .carrier_mix1_sign(mix_qi_sign), .carrier_mix1_mag(mix_qi_mag),
                             .carrier_mix2_sign(mix_iq_sign), .carrier_mix2_mag(mix_iq_mag),
                             .dump_enable(dump_enable), .accumulation(q_prompt)
                            );
  // quadrature-phase late
  accumulator_two_inputs ql (.clk(clk), .rstn(rstn), .sample_enable(accum_sample_enable), .code(late_code),
                             .carrier_mix1_sign(mix_qi_sign), .carrier_mix1_mag(mix_qi_mag),
                             .carrier_mix2_sign(mix_iq_sign), .carrier_mix2_mag(mix_iq_mag),
                             .dump_enable(dump_enable), .accumulation(q_late)
                            );
  //-------------------------------------------------------------------------
  `endif
   
  assign test_point_01 = hc_enable;
  assign test_point_02 = hc_enable;
  assign test_point_03 = prompt_code;
   
endmodule // tracking_channel

   
			
			
      
			 

