/*
 *  Wishbone asynchronous bridge
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

module wb_abrg (
    input sys_rst,

    // Wishbone slave interface
    input             wbs_clk_i,
    input      [31:0] wbs_adr_i,
    input      [31:0] wbs_dat_i,
    output reg [31:0] wbs_dat_o,
    input      [ 3:0] wbs_sel_i,
    input      [ 2:0] wbs_cti_i,
    input             wbs_stb_i,
    input             wbs_cyc_i,
    input             wbs_we_i,
    output            wbs_ack_o,

    // Wishbone master interface
    input          wbm_clk_i,
    output  [31:0] wbm_adr_o,
    output  [31:0] wbm_dat_o,
    input   [31:0] wbm_dat_i,
    output  [ 3:0] wbm_sel_o,
    output  [ 2:0] wbm_cti_o,
    output         wbm_stb_o,
    output         wbm_cyc_o,
    output         wbm_we_o,
    input          wbm_ack_i
  );

reg [3:0] sw;
wire en50;
//reg stb;

assign en50=wbs_clk_i;
  
assign  wbm_adr_o = wbs_adr_i; 
assign  wbm_dat_o = wbs_dat_i; 
//assign  wbs_dat_o = wbm_dat_i; 

assign  wbm_sel_o = wbs_sel_i; 
assign  wbm_cti_o = wbs_cti_i; 

assign  wbm_stb_o = wbs_stb_i & (sw==4'd0); 
assign  wbm_cyc_o = wbs_cyc_i; 
assign  wbm_we_o  = wbs_we_i; 

//assign  wbs_ack_o = wbm_ack_i; 

parameter s0		= 4'd0;
parameter s1    	= 4'd1;
parameter s2		= 4'd2;

parameter s3		= 4'd3;
parameter s4		= 4'd4;
parameter s5		= 4'd5;
parameter s6		= 4'd6;

assign  wbs_ack_o = (sw==4'd2)|(sw==4'd3);

always @(posedge wbm_clk_i or posedge sys_rst)
  begin
   if (sys_rst)
    sw <= s0;
   else
    begin
     case (sw)
                s0: if (wbm_ack_i)
				         if (en50)
                            sw <= s2;
					     else 
                            sw <= s1;
                s1: if (en50)
				      sw <= s2;
                s2: sw <= s3;
                s3: sw <= s0;
				default: sw <= s0;
     endcase
    end
end						
  
//  always @(posedge wbm_clk_i)
//    if (wbm_ack_i)
//	 stb<=1'b0;
//	else if (sw==s0)
//     stb <= wbs_sel_i;

  always @(posedge wbm_clk_i)
   if (wbm_ack_i)
    wbs_dat_o <=  wbm_dat_i;

endmodule
