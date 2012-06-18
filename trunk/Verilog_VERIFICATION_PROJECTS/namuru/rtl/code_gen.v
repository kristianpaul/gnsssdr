//                              -*- Mode: Verilog -*-
// Filename        : code_gen.v
// Description     : Generates early prompt and late C/A code chips.

// Author          : Peter Mumford, 2005, UNSW

// Function        : Generate the C/A code early, prompt and late chipping sequence.

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

module code_gen (clk, rstn, 
                 tic_enable, hc_enable, 
                 `ifdef ENABLE_GLONASS
                 glns_or_gps,
                 `endif
                 prn_key_enable, prn_key, 
                 code_slew, slew_enable,
                 dump_enable, 
                 code_phase, 
                 early, prompt, late);

  input clk, rstn;
  input tic_enable;       // the TIC
  input hc_enable;        // the half-chip enable pulse from the code_nco
  `ifdef ENABLE_GLONASS
  input glns_or_gps;      // [Art] GLONASS or GPS Code generator (1 = GLONASS, 0 = GPS)
  `endif
  input [9:0] prn_key;    // 10 bit number used to select satellite PRN code
  input prn_key_enable;   // pulse to latch in the prn_key and reset the logic (write & chip_select)
  input slew_enable;      // pulse to set the slew_flag (write & chip select)
  input [10:0] code_slew; // number of half chips to delay the C/A code after the next dump_enable 

  output dump_enable;          // pulse at the begining/end of prompt C/A code cycle
  output reg [10:0] code_phase;// the phase of the C/A code at the TIC
  output early, prompt, late;  // half-chip spaced C/A code sequences

  reg [9:0] g1;          // the g1 shift register
  reg g1_q;              // output of the g1 shift register
  reg [9:0] g2;          // the g2 shift register
  reg g2_q;              // output of the g2 shift register
  `ifdef ENABLE_GLONASS
  reg [8:0] g3;          // [Art] g3 shift register for GLONASS code generator
  reg g3_q;              // [Art] output of the g3 shift register
  `endif
  //wire ca_code;          // the C/A code chip sequence from g1 and g2 shifters
  wire [2:0] srq;        // the output of the chip spreader
   
  reg fc_enable;         // full-chip enable that drives the g1 and g2 shifters
  reg dump_enable;       // pulse generated at the begining/end of the prompt C/A code cycle
  reg [10:0] hc_count1;  // counter used for generating the fc_enable and slew logic (max slew 2045)

  reg [10:0] slew;       // the code_slew latched if the slew_flag is set  
  reg [11:0] hc_count2;  // counter for keeping track of the begining/end of C/A code cycle (max count 4091)
  reg [11:0] max_count2; // limit of hc_count2, normally = 2045, but increased when slew delays the C/A code
   
  //reg [1:0] dump = 3;    // dump_enable is generated when hc_count2 = 3
  reg slew_flag;         // slew_flag is set on the slew_enable pulse and cleared on the dump_enable
  reg slew_trigger;      // triggers the slew event

  reg [10:0] hc_count3;  // this counter is reset at the dump_enable, latched into the code_phase on the TIC
   
  //shift register GavAI implementation.
  reg [2:0] shft_reg;
  
    
  // The G1 shift register
  //----------------------
  always @ (posedge clk)
  begin
    if (prn_key_enable) // set up shift register
    begin
      g1_q <= 0;
      g1 <= 10'b1111111111;
    end
    else if (fc_enable) // run
    begin
      g1_q <= g1[0];
      g1 <= {(g1[7] ^ g1[0]), g1[9:1]};
    end
  end

  // The G2 shift register
  //----------------------
  always @ (posedge clk)
  begin
    if (prn_key_enable) // set up shift register
    begin
      g2_q <= 0;
      g2 <= prn_key;
    end
    else if (fc_enable) // run
    begin
      g2_q <= g2[0];
      g2 <= {(g2[8] ^ g2[7] ^ g2[4] ^ g2[2] ^ g2[1] ^ g2[0]), g2[9:1]};
    end
  end

  `ifdef ENABLE_GLONASS
  // The G3 shift register
  //----------------------
  always @ (posedge clk)
  begin
    if (prn_key_enable) // set up shift register
    begin
      g3_q <= 0;
      g3   <= 9'b111111111;
    end
    else if (fc_enable) // run
    begin
      g3_q <= g3[2];
      g3   <= {(g3[4] ^ g3[0]), g3[8:1]};
    end
  end
  `endif

  ///assign ca_code = g1_q ^ g2_q;

  `ifdef ENABLE_GLONASS // [Art] GLONASS or GPS Code generator (1 = GLONASS, 0 = GPS)
  wire ca_code = ( glns_or_gps == 1'b1 ) ? g3_q : (g1_q ^ g2_q);
  `else
  wire ca_code = g1_q ^ g2_q;
  `endif
  
  always @ (posedge clk)
  begin
    if (prn_key_enable) //clear register;
	  shft_reg <= 0;
	else if (hc_enable) //make shifting here;
	  shft_reg <= {shft_reg[1:0], ca_code};
  end
  assign srq = shft_reg;   

  // assign the early, prompt and late chips, one half chip apart
  assign early = srq[0];
  assign prompt = srq[1];
  assign late = srq[2];

  // hc_count3 process
  //------------------
  // Counter 3 counts hc_enables, reset on dump_enable.
  // If there is slew delay this counter will roll over
  // before the next dump. However, code_phase measurements
  // are not valid during slewing.
  always @ (posedge clk)
  begin
    if (prn_key_enable || dump_enable)
      hc_count3 <= 0;
    else if (hc_enable)
      hc_count3 <= hc_count3 + 1;
  end
   
  // capture the code phase at TIC
  //------------------------------
  // The code_phase is the half-chip count
  // at the TIC. Half-chips are numbered 0 to 2045.
  // The code_nco_phase (from the code_nco) provides
  // the fine (sub half-chip) code phase.
  always @ (posedge clk)
  begin
    if (tic_enable)
      code_phase <= hc_count3;
  end

  // The full-chip enable generator
  //--------------------------------
  // Without the code_slew being set
  // this process just creates the full-chip enable
  // at half the rate of the half-chip enable.
  // When the code_slew is set, the fc_enable
  // is delayed for a number of half-chips.
  always @ (posedge clk)
  begin
    if (prn_key_enable)
    begin
      hc_count1 <= 0;
      fc_enable <= 0;
      slew <= 0; // reset slew   
    end
    else
    begin 
      if (slew_trigger)
        slew <= code_slew;
      if (hc_enable)
      begin
        if (slew == 0) // no delay on code
        begin
          if (hc_count1 == 1)
          begin
            hc_count1 <= 0;
            fc_enable <= 1; // create fc_enable pulse
          end
          else
            hc_count1 <= hc_count1 + 1; // increment count
        end
        else
          slew <= slew - 1; // decrement slew
      end
      else
        fc_enable <= 0;
    end
  end

  // The dump_enable generator
  //--------------------------
  // create the dump_enable
  //
  // When a slew value (= x) is written to the code_slew register,
  // the C/A code is delayed x half-chips at the next dump.
  always @ (posedge clk)
  begin
  if (prn_key_enable)
  begin
    dump_enable <= 0;
    hc_count2 <= 0;
    slew_trigger <= 0;
    `ifndef ENABLE_GLONASS
    max_count2 <= 2045; // normal half-chip count in one C/A cycle
    `else
    if (glns_or_gps == 1'b0)
      max_count2 <= 2045; // normal half-chip count in one GPS C/A cycle
    else
      max_count2 <= 1021; // normal half-chip count in one GLONASS C/A cycle
    `endif
  end
     
  else if (hc_enable)
  begin
    hc_count2 <= hc_count2 + 1;
    if (hc_count2 == 3)//dump)
      dump_enable <= 1;
    else if (hc_count2 == max_count2)
      hc_count2 <= 0;
    else if (hc_count2 == 1)  // signals the arrival of the first hc_enable
    begin
      if (slew_flag) // slew delay
      begin
        slew_trigger <= 1;
        `ifndef ENABLE_GLONASS
        max_count2 <= 2045 + code_slew;
        `else
        if (glns_or_gps == 1'b0)
          max_count2 <= 2045 + code_slew;
        else
          max_count2 <= 1021 + code_slew;
        `endif
      end
      else
        `ifndef ENABLE_GLONASS
        max_count2 <= 2045;
        `else
        if (glns_or_gps == 1'b0)
          max_count2 <= 2045;
        else
          max_count2 <= 1021;
        `endif
      end
    end
  else
  begin
    dump_enable <= 0;
    slew_trigger <= 0;
  end

  end     

   
  // slew_flag process
  //------------------
  // The slew_flag is set on slew_enable and cleared on the dump_enable.
  always @ (posedge clk)
  begin
    if (prn_key_enable)
      slew_flag <= 0;
    else if (slew_enable)
      slew_flag <= 1;
    else if (dump_enable)
      slew_flag <= 0;
  end
    
endmodule // code_gen

   
