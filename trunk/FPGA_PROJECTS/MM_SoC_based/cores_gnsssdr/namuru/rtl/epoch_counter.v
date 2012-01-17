//                              -*- Mode: Verilog -*-
// Filename        : epoch_counter.v
// Description     : Count the C/A code cycles.

// Author          : Peter Mumford, UNSW, 2005

/*                 C/A code cycles are counted by two counters;
                   the 1ms epoch counter (or cycle counter)
                   and the 20ms epoch counter (or bit counter).
                   The 1ms epoch counter counts C/A code cycles (by 
                   counting dump_enable pulses) that occur every 1ms
                   from 0 to 19. This allows the tracking of the bit
                   boundaries in the broadcast message that occur every
                   20ms. Every time this counter rolls over, the 20ms
                   epoch counter increments. The 20ms epoch counter
                   goes from 0 to 49 to allow tracking of the message
                   frame boundary.

                   The 1ms epoch count is 5 bits wide.
                   The 20ms count count is 6 bits wide.

                   The values are latched into epoch on the tic_enable.
                   The epoch_check is for instantaneous values used for finding
                   message bit flips.
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

module epoch_counter (clk, rstn, tic_enable, dump_enable, epoch_enable, epoch_load, epoch, epoch_check);

   input clk, rstn, tic_enable, dump_enable, epoch_enable;
   input [10:0] epoch_load;
   output reg [10:0] epoch;
   output reg [10:0]epoch_check;

   reg [4:0] cycle_count;
   reg [5:0] bit_count;
   wire cycle_count_overflow;
   
// the 1ms epoch (C/A code cycle) counter
   always @ (posedge clk)
   begin
	 if (!rstn) cycle_count <= 0;
	 else if (epoch_enable)
	      cycle_count <= epoch_load[4:0];
	 else if (dump_enable)
	    begin
	      if (cycle_count_overflow) cycle_count <= 0;
	      else cycle_count <= cycle_count + 1;
	    end
   end
   
// look for the overflow
   assign cycle_count_overflow = (cycle_count == 19)? 1:0;

// the 20ms epoch (bit flip) counter
   always @ (posedge clk)
   begin
	 if (!rstn) bit_count <= 0;
	 else if (epoch_enable)
		 bit_count <= epoch_load[10:5];
	 else if (cycle_count_overflow & dump_enable)
	    begin
	      if (bit_count == 49) bit_count <= 0;
	      else bit_count <= bit_count + 1;
	    end
   end

// latch the epoch into a register   
   always @ (posedge clk)
   begin
   if (tic_enable)
      begin
	    epoch[4:0] <= cycle_count;
	    epoch[10:5] <= bit_count;
      end
   end

   always @ (posedge clk)
   begin
      epoch_check[4:0] <= cycle_count;
      epoch_check[10:5] <= bit_count;
   end
   
endmodule // epoch_counter

   