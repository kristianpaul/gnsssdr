//                              -*- Mode: Verilog -*-
// Filename        : carrier_mixer.v
// Description     : Mix together the incomming signal with the local carrier.

// Author          : Peter Mumford, UNSW, 2005


/*
 The IF raw data and carrier are two bit quantities.
 Each has a sign bit and a mag bit.
 The IF_mag bit represents the values 1 and 3.
 The carrier_mag bit represents the values 1 and 2.

 The mix_mag is three bits representing the values 1,2,3,6
 The mix_sign bit is 0 for negative, 1 for positive.

 truth table

 if_mag       | 0 0 1 1 |
 carrier_mag  | 0 1 0 1 |
 output bit:
            0 | 1 0 1 0 | = not carrier_mag

            1 | 0 1 1 1 | = if_mag or carrier_mag
            2 | 0 0 0 1 | = if_mag and carrier_mag
 -------------|---------|
    value     | 1 2 3 6 |

 if_sign      | 0 0 1 1 |  (0 = -ve, 1 = +ve)
 carrier sign | 0 1 0 1 |
 output sign:
              | 1 0 0 1 |  = not( if_sign xor carrier_sign )
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

module carrier_mixer (if_sign, if_mag, carrier_sign, carrier_mag, mix_sign, mix_mag);

input if_sign, if_mag, carrier_sign, carrier_mag;
output mix_sign;
output [2:0] mix_mag;

assign mix_mag[0] = !carrier_mag;
assign mix_mag[1] = if_mag | carrier_mag;
assign mix_mag[2] = if_mag & carrier_mag;
assign mix_sign = !(if_sign ^ carrier_sign);

endmodule


