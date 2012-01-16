/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

module hpdmc_ddrio(
	input sys_clk,
	input sys_clk_n,
	input dqs_clk,
	input dqs_clk_n,
	
	input direction,
	input direction_r,
	input [3:0] mo,
	input [31:0] do,
	output [31:0] di,
	
	output [1:0] sdram_dqm,
	inout [15:0] sdram_dq,
	inout [1:0] sdram_dqs,
	
	input idelay_rst,
	input idelay_ce,
	input idelay_inc
);

/******/
/* DQ */
/******/

wire [15:0] sdram_dq_t;
wire [15:0] sdram_dq_out;
wire [15:0] sdram_dq_in;

hpdmc_iobuf16 iobuf_dq(
	.T(sdram_dq_t),
	.I(sdram_dq_out),
	.O(sdram_dq_in),
	.IO(sdram_dq)
);

reg [15:0] dr;
always @(posedge sys_clk) dr <= {16{~direction_r}};

hpdmc_oddr16 oddr_dq_t(
	.Q(sdram_dq_t),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D0({16{~direction_r}}),
//	.D1({32{~direction_r}}),
	.D1(dr),
	.R(1'b0),
	.S(1'b0)
);
//======================================================================
wire [15:0] do1;

fdce16 FDCE_w (
    .q(do1), // Data output
    .c(sys_clk), // Clock input
    .ce(1'b1), // Clock enable input
    .clr(1'b0), // Asynchronous clear input
    .d(do[15:0]) // Data input
);

//======================================================================

hpdmc_oddr16 oddr_dq(
	.Q(sdram_dq_out),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D0(do[31:16]),
//	.D1(do[31:0]),
	.D1(do1),
	.R(1'b0),
	.S(1'b0)
);
//======================================================================
wire [15:0] di1;

fdce16 FDCE_1 (
    .q(di[31:16]), // Data output
    .c(sys_clk), // Clock input
    .ce(1'b1), // Clock enable input
    .clr(1'b0), // Asynchronous clear input
    .d(di1) // Data input
);

hpdmc_iddr16 iddr_dq(
	.Q0(di[15:0]),
	.Q1(di1),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D(sdram_dq_in),
	.R(1'b0),
	.S(1'b0)
);

//======================================================================


/*******/
/* DQM */
/*******/
wire [1:0] dm1;
//always @(sys_clk) dm1 <= mo[1:0];

fdce2 FDCE_dm (
    .q(dm1[1:0]), // Data output
    .c(sys_clk), // Clock input
    .ce(1'b1), // Clock enable input
    .clr(1'b0), // Asynchronous clear input
    .d(mo[1:0]) // Data input
);


hpdmc_oddr2 oddr_dqm(
	.Q(sdram_dqm),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D0(mo[3:2]),
//	.D1(mo[3:0]),
	.D1(dm1),
	.R(1'b0),
	.S(1'b0)
);

/*******/
/* DQS */
/*******/

wire [1:0] sdram_dqs_t;
wire [1:0] sdram_dqs_out;

hpdmc_obuft2 obuft_dqs(
	.T(sdram_dqs_t),
	.I(sdram_dqs_out),
	.O(sdram_dqs)
);

wire [1:0] dqst1;
//always @(posedge sys_clk) dqst1 <= {2{~direction_r}};

fdce2 FDCE_dqs (
    .q( dqst1), // Data output
    .c(dqs_clk), // Clock input
    .ce(1'b1), // Clock enable input
    .clr(1'b0), // Asynchronous clear input
    .d( {2{~direction_r}}) // Data input
);


hpdmc_oddr2 oddr_dqs_t(
	.Q(sdram_dqs_t),
	.C0(dqs_clk),
	.C1(dqs_clk_n),
	.CE(1'b1),
	.D0({2{~direction_r}}),
//	.D1({4{~direction_r}}),
	.D1(dqst1),
	.R(1'b0),
	.S(1'b0)
);


hpdmc_oddr2 oddr_dqs(
	.Q(sdram_dqs_out),
	.C0(dqs_clk),
	.C1(dqs_clk_n),
	.CE(1'b1),
	.D0(2'h3),
	.D1(2'h0),
	.R(1'b0),
	.S(1'b0)
);

endmodule
