//                              -*- Mode: Verilog -*-
// Filename        : accumulator.v
// Description     : accumulate and dump process

// Author          : Peter Mumford, UNSW, 2005
// Code updated    : Artyon Favrilov, gnss-sdr.com, 2012
/*
 carrier_mix_sign provides the sign.
 0 for negative, 1 for positive.
 The three magnitude bits represent the values 1,2,3,6.
 
 The code is 0 or 1 representing -1 or 1 respectively.
 
 The multiplication of the carrier_mix and the code
 is simply the carrier_mix_mag with the sign determined
 from the multiplication of the carrier_mix sign and the code.
 
 code              0 0 1 1
 carrier_mix_sign  0 1 0 1
                   -------
 result            1 0 0 1  (0 for -ve, 1 for +ve)
 
 if (code == carrier_mix_sign) result = 1
 else result = 0
 */
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

module accumulator_two_inputs (clk, rstn, sample_enable, code, carrier_mix1_sign, carrier_mix1_mag, carrier_mix2_sign, carrier_mix2_mag, dump_enable, accumulation);
  input clk, rstn, sample_enable, dump_enable;
  input carrier_mix1_sign, carrier_mix2_sign;
  input [2:0] carrier_mix1_mag, carrier_mix2_mag;
  input code;

  output [15:0] accumulation;

  reg [15:0] accum_i;
  reg [15:0] accumulation;

  always @ (posedge clk)
  begin
    if (!rstn)
    begin
      accumulation <= 0;
      accum_i <= 0;
    end
    else if (dump_enable)
    begin
      accumulation <= accum_i;  // buffer the accumultion...
      accum_i <= 0;             // then reset the accumulation 	//xilinx ISE error!
    end
    else if (sample_enable) // 20 MHz rate
    begin
      if ( (code == carrier_mix1_sign) && (code == carrier_mix2_sign) )
        accum_i <= accum_i + {13'b0000000000000, carrier_mix1_mag} + {13'b0000000000000, carrier_mix2_mag};
      else if ( (code != carrier_mix1_sign) && (code != carrier_mix2_sign) )
        accum_i <= accum_i - {13'b0000000000000, carrier_mix1_mag} - {13'b0000000000000, carrier_mix2_mag};
      else if ( (code == carrier_mix1_sign) && (code != carrier_mix2_sign) )
        accum_i <= accum_i + {13'b0000000000000, carrier_mix1_mag} - {13'b0000000000000, carrier_mix2_mag};
      else if ( (code != carrier_mix1_sign) && (code == carrier_mix2_sign) )
        accum_i <= accum_i - {13'b0000000000000, carrier_mix1_mag} + {13'b0000000000000, carrier_mix2_mag};
      end
    end // always @ (posedge clk)
endmodule // accumulator_two_inputs


