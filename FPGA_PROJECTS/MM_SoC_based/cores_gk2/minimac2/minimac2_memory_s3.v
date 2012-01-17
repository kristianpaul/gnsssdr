/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module minimac2_memory(
	input sys_clk,
	input sys_rst,
	input phy_rx_clk,
	input phy_tx_clk,
	
	input [31:0] wb_adr_i,
	output[31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	input wb_we_i,
	
	input [7:0] rxb0_dat,
	input [10:0] rxb0_adr,
	input rxb0_we,
	input [7:0] rxb1_dat,
	input [10:0] rxb1_adr,
	input rxb1_we,
	
	output [7:0] txb_dat,
	input [10:0] txb_adr

);

wire wb_en = wb_cyc_i & wb_stb_i;
wire [1:0] wb_buf = wb_adr_i[12:11];
wire [31:0] wb_dat_i_le = {wb_dat_i[7:0], wb_dat_i[15:8], wb_dat_i[23:16], wb_dat_i[31:24]};
wire [3:0] wb_sel_i_le = {wb_sel_i[0], wb_sel_i[1], wb_sel_i[2], wb_sel_i[3]};

wire [31:0] wb_dat_i_le1;
wire [31:0] rxb0_wbdat;
reg wb0, wb1, wb2;
reg [31:0] wb_dat_o_le;

assign  wb_dat_i_le1[ 7:0 ] = wb_sel_i_le[0] ? wb_dat_i_le[ 7:0 ] : wb_dat_o_le[ 7:0 ];
assign  wb_dat_i_le1[15:8 ] = wb_sel_i_le[1] ? wb_dat_i_le[15:8 ] : wb_dat_o_le[15:8 ];
assign  wb_dat_i_le1[23:16] = wb_sel_i_le[2] ? wb_dat_i_le[23:16] : wb_dat_o_le[23:16];
assign  wb_dat_i_le1[31:24] = wb_sel_i_le[3] ? wb_dat_i_le[31:24] : wb_dat_o_le[31:24];

RAMB16_S9_S36 #(
	.WRITE_MODE_A("WRITE_FIRST"),
	.WRITE_MODE_B("WRITE_FIRST")
) rxb0 (
	.DIB(wb_dat_i_le1),
	.DIPB(4'd0),
	.DOB(rxb0_wbdat),
    .DOPB(),
	.ADDRB(wb_adr_i[10:2]),
//	.WEB((wb_en & wb_we_i & (wb_buf == 2'b00)) & wb_sel_i_le),
	.WEB(wb0),
	.ENB(1'b1),
	.SSRB(1'b0),
	.CLKB(sys_clk),

	.DIA(rxb0_dat),
	.DIPA(1'd0),
	.DOA(),
    .DOPA(),
	.ADDRA(rxb0_adr),
	.WEA(rxb0_we),
	.ENA(1'b1),
	.SSRA(1'b0),
	.CLKA(phy_rx_clk)
);

wire [31:0] rxb1_wbdat;
RAMB16_S9_S36 #(
	.WRITE_MODE_A("WRITE_FIRST"),
	.WRITE_MODE_B("WRITE_FIRST")
) rxb1 (
	.DIB(wb_dat_i_le1),
	.DIPB(4'd0),
	.DOB(rxb1_wbdat),
    .DOPB(),
	.ADDRB(wb_adr_i[10:2]),
//	.WEB((wb_en & wb_we_i & (wb_buf == 2'b01)) & wb_sel_i_le),
	.WEB(wb1),
	.ENB(1'b1),
	.SSRB(1'b0),
	.CLKB(sys_clk),

	.DIA(rxb1_dat),
	.DIPA(1'd0),
	.DOA(),
    .DOPA(),
	.ADDRA(rxb1_adr),
	.WEA(rxb1_we),
	.ENA(1'b1),
	.SSRA(1'b0),
	.CLKA(phy_rx_clk)
);

wire [31:0] txb_wbdat;
RAMB16_S9_S36 #(
	.WRITE_MODE_A("WRITE_FIRST"),
	.WRITE_MODE_B("WRITE_FIRST")
) txb (
	.DIB(wb_dat_i_le1),
	.DIPB(4'd0),
	.DOB(txb_wbdat),
    .DOPB(),
	.ADDRB(wb_adr_i[10:2]),
//	.WEB((wb_en & wb_we_i & (wb_buf == 2'b10)) & wb_sel_i_le),
	.WEB(wb2),
	.ENB(1'b1),
	.SSRB(1'b0),
	.CLKB(sys_clk),

	.DIA(8'd0),
	.DIPA(1'd0),
	.DOA(txb_dat),
    .DOPA(),
	.ADDRA(txb_adr),
	.WEA(1'd0),
	.ENA(1'b1),
	.SSRA(1'b0),
	.CLKA(phy_tx_clk)
);

always @(posedge sys_clk) begin
	if(sys_rst)
     begin
		wb0 <= 1'b0;
		wb1 <= 1'b0;
		wb2 <= 1'b0;
     end   
	else begin
          wb0 <= 1'b0;
		  wb1 <= 1'b0;
		  wb2 <= 1'b0;
		if( wb_en & ~wb_ack_o) begin
            wb0 <= wb_we_i & (wb_buf == 2'b00);
	        wb1 <= wb_we_i & (wb_buf == 2'b01);
		    wb2 <= wb_we_i & (wb_buf == 2'b10);
           end 
	     end
end

always @(posedge sys_clk) begin
	if(sys_rst)
		wb_ack_o <= 1'b0;
	else begin
		  wb_ack_o <= 1'b0;
		if(wb_en & ~wb_ack_o) 
			wb_ack_o <= 1'b1;
	     end
end


reg [1:0] wb_buf_r;
always @(posedge sys_clk)
	wb_buf_r <= wb_buf;

always @(*) begin
	case(wb_buf_r)
		2'b00: wb_dat_o_le = rxb0_wbdat;
		2'b01: wb_dat_o_le = rxb1_wbdat;
		default: wb_dat_o_le = txb_wbdat;
	endcase
end
 
assign wb_dat_o = {wb_dat_o_le[7:0], wb_dat_o_le[15:8], wb_dat_o_le[23:16], wb_dat_o_le[31:24]};

endmodule
