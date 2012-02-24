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

`include "setup.v"
`include "lm32_include.v"

module system(

`ifdef EXTERNAL_CLOCK
	input clk16,
`else
	input clk50,
`endif
   
	input res,

	// Boot ROM
	output [23:0] flash_adr,
	inout [15:0] flash_d,
	output flash_oe_n,
	output flash_we_n,
	output flash_ce_n,
	output flash_rst_n,
	//input flash_sts,

	// UART
	input uart_rx,
	output uart_tx,

	// GPIO
	input  btn1,
	input  btn2,
	input  btn3,
	output led1,
	output led2,

	// DDR SDRAM
	output sdram_clk_p,
	output sdram_clk_n,
	output sdram_cke,
	output sdram_cs_n,
	output sdram_we_n,
	output sdram_cas_n,
	output sdram_ras_n,
	output [1:0]  sdram_dm,
	output [12:0] sdram_adr,
	output [1:0]  sdram_ba,
	inout  [15:0] sdram_dq,
	inout  [1:0]  sdram_dqs,
    
	// Ethernet
	//output phy_rst_n,
	input phy_tx_clk,
	output [3:0] phy_tx_data,
	output phy_tx_en,
	output phy_tx_er,
	input phy_rx_clk,
	input [3:0] phy_rx_data,
	input phy_dv,
	input phy_rx_er,
	//input phy_col,
	//input phy_crs,
	//input phy_irq_n,
	output phy_mii_clk,
	inout phy_mii_data,
	//output reg phy_clk,
//=================== LCD ============================== 
    output    lcd_rw,
    output    lcd_e,
    output    lcd_rs,
	
//================== disable  ==========================        
    output    pf_oe,
    output    spi_rom_cs,
    output    spi_adc_conv, 
    output    spi_dac_cs,
	 
//===================Art!===============================
	//correlator signals:
	output accum_int,
	input  sign_i,
	input  sign_q,
	
	input  inpt_01,
	//test points for debugging: 
	output test_point_01,
	output test_point_02,
	output test_point_03,
	output test_point_04,
	output test_point_05
	
);

//------------------------------------------------------------------
// Clock and Reset Generation
//------------------------------------------------------------------
`ifdef EXTERNAL_CLOCK
wire clk50; //Art!
`endif

wire [3:0] pcb_revision=4'b0010;

wire sys_clk;
wire sys_clk100;
wire sys_clk100_n;

wire hard_reset;
wire reset_button = res;

assign  lcd_rw       = 1'b0;    //  Always writing to display prevents display driving out.
//assign  lcd_e        = 1'b0;    //  No enable pulses to the display ensures that display contents do not change.
assign  pf_oe        = 1'b0;    //  Disable (reset) Platform FLASH device used in master serial configuration.
assign  spi_rom_cs   = 1'b1;    //  Disable SPI FLASH device used in SPI configuration.
assign  spi_adc_conv = 1'b0;    //  Prevent SPI based A/D converter from generating sample data.
assign  spi_dac_cs   = 1'b1;    //  Disable SPI based D/A converter interface.

//========================================================================

//---------------
`ifdef EXTERNAL_CLOCK
wire sys0_clk_dcm;

DCM_SP #(
	.CLKDV_DIVIDE(2.0),		// 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5

	.CLKFX_DIVIDE(1),		// 1 to 32
	.CLKFX_MULTIPLY(3),		// 2 to 32

	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(20.8),
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
	.CLKIN(clk16),
	.RST(1'b0),
	.PSEN(1'b0)
);
BUFG b0(
	.I(sys0_clk_dcm),
	.O(clk50) //in fact we have 48 MHz not 50 MHz.
);
`endif

//---------------

wire sys_clk_dcm;
wire sys_clk_n_dcm;
wire locked;

DCM_SP #(
	.CLKDV_DIVIDE(1.5),		// 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5

	.CLKFX_DIVIDE(1),		// 1 to 32
	.CLKFX_MULTIPLY(2),		// 2 to 32

	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(20.0),
	.CLKOUT_PHASE_SHIFT("NONE"),
	.CLK_FEEDBACK("2X"),
	.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
	.DFS_FREQUENCY_MODE("LOW"),
	.DLL_FREQUENCY_MODE("LOW"),
	.DUTY_CYCLE_CORRECTION("TRUE"),
	.PHASE_SHIFT(0),
	.STARTUP_WAIT("TRUE")
) clkgen_sys (
	.CLK0(sys_clkh),
	.CLK90(),
	.CLK180(),
	.CLK270(),

	.CLK2X(sys_clk_dcm),
	.CLK2X180(sys_clk_n_dcm),

	.CLKDV(),
	.CLKFX(),
	.CLKFX180(),
	.LOCKED(locked),
	.CLKFB(sys_clk100),
	.CLKIN(clk50),
	.RST(1'b0),
	.PSEN(1'b0)
);
BUFG b1(
	.I(sys_clk_dcm),
	.O(sys_clk100)
);
BUFG b2(
	.I(sys_clk_n_dcm),
	.O(sys_clk100_n)
);

BUFG b3(
	.I(sys_clkh),
	.O(sys_clk)
);

reg tt1;
reg [2:0] sw;
reg en50;	
				
parameter sw0 = 3'b000; parameter sw1 = 3'b001; parameter sw2 = 3'b011;
parameter sw3 = 3'b010; parameter sw4 = 3'b110; parameter sw5 = 3'b111;

initial tt1 <= 1'b0;
always @(posedge sys_clk) 
 if (locked)
  tt1 <= #1 ~tt1;
 else 
  tt1<=1'b0;
  
//===================================================================================================

always @(posedge sys_clk100 )
  begin
   if (~locked)
    sw <= sw0;
   else
    begin
     case (sw)
       sw0: if (~tt1) sw <= sw1;
       sw1: if (tt1) sw <= sw2;
       sw2: sw <= sw3;
       sw3: sw <= sw4;
       sw4: sw <= sw5;
       sw5: sw <= sw2;
	   default: sw <= sw0;
     endcase
    end
end	

always @(posedge sys_clk100) 
 if (~locked)
  en50 <= 1'b0;
 else 
  if ((sw==sw3)||(sw==sw5))
    en50<=1'b1;
  else	
    en50<=1'b0;

//========================================================================

reg trigger_reset;
always @(posedge sys_clk) trigger_reset <= hard_reset|reset_button;
reg [19:0] rst_debounce;
reg sys_rst;
initial rst_debounce <= 20'h000FF;

initial sys_rst <= 1'b1;
always @(posedge sys_clk) begin
	if(trigger_reset)
		rst_debounce <= 20'h000FF;
	else if(rst_debounce != 20'd0)
		rst_debounce <= rst_debounce - 20'd1;
	sys_rst <= rst_debounce != 20'd0;
end

assign flash_rst_n =  1'b1; // use for BYTE / WORD select

//------------------------------------------------------------------
// Wishbone master wires
//------------------------------------------------------------------
wire [31:0]	cpuibus_adr,
		cpudbus_adr;

wire [2:0]	cpuibus_cti,
		cpudbus_cti;

wire [31:0]	cpuibus_dat_r,
`ifdef CFG_HW_DEBUG_ENABLED
		cpuibus_dat_w,
`endif
		cpudbus_dat_r,
		cpudbus_dat_w;

wire [3:0]	cpudbus_sel;
`ifdef CFG_HW_DEBUG_ENABLED
wire [3:0]	cpuibus_sel;
`endif

wire
`ifdef CFG_HW_DEBUG_ENABLED
		cpuibus_we,
`endif
		cpudbus_we;

wire	cpuibus_cyc,
		cpudbus_cyc;

wire	cpuibus_stb,
		cpudbus_stb;

wire	cpuibus_ack,
		cpudbus_ack;

//------------------------------------------------------------------
// Wishbone slave wires
//------------------------------------------------------------------
wire [31:0]	norflash_adr,
		monitor_adr,
		usb_adr,
		eth_adr,
		brg_adr,brg_adr1,
		csrbrg_adr,
		namuru_adr;

wire [2:0]	brg_cti, brg_cti1;

wire [31:0]	norflash_dat_r,
		norflash_dat_w,
		monitor_dat_r,
		monitor_dat_w,
		eth_dat_r,
		eth_dat_w,
		brg_dat_r, brg_dat1_r,
		brg_dat_w, brg_dat1_w,
		csrbrg_dat_r,
		csrbrg_dat_w,
		namuru_dat_r,
		namuru_dat_w;

wire [3:0]	norflash_sel,
		monitor_sel,
		eth_sel,
		brg_sel, brg_sel1,
		namuru_sel;

wire	norflash_we,
		monitor_we,
		eth_we,
		brg_we, brg_we1,
		csrbrg_we,
		namuru_we;

wire	norflash_cyc,
		monitor_cyc,
        eth_cyc,
		brg_cyc, brg_cyc1,
		csrbrg_cyc,
		namuru_cyc;

wire	norflash_stb,
		monitor_stb,
        eth_stb,
		brg_stb,  brg_stb1,
		csrbrg_stb,
		namuru_stb;

wire	norflash_ack,
		monitor_ack,
        eth_ack,
		brg_ack, brg_ack1,
		csrbrg_ack,
		namuru_ack;

//---------------------------------------------------------------------------
// Wishbone switch
//---------------------------------------------------------------------------
// norflash     0x00000000 (shadow @0x80000000)
// debug        0x10000000 (shadow @0x90000000)
// USB          0x20000000 (shadow @0xa0000000)	// Namuru Correlator 0x70000000;
// Ethernet     0x30000000 (shadow @0xb0000000)
// SDRAM        0x40000000 (shadow @0xc0000000)
// CSR bridge   0x60000000 (shadow @0xe0000000)

// MSB (Bit 31) is ignored for slave address decoding
conbus5x6 #(
  .s0_addr(3'b000), // norflash
  .s1_addr(3'b001), // debug
  .s2_addr(3'b010),	// Namuru correlator
  .s3_addr(3'b011), // Ethernet
  .s4_addr(2'b10),  // SDRAM
  .s5_addr(2'b11)   // CSR
) wbswitch (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	// Master 0
`ifdef CFG_HW_DEBUG_ENABLED
	.m0_dat_i(cpuibus_dat_w),
`else
	.m0_dat_i(32'hx),
`endif
	.m0_dat_o(cpuibus_dat_r),
	.m0_adr_i(cpuibus_adr),
	.m0_cti_i(cpuibus_cti),
`ifdef CFG_HW_DEBUG_ENABLED
	.m0_we_i(cpuibus_we),
	.m0_sel_i(cpuibus_sel),
`else
	.m0_we_i(1'b0),
	.m0_sel_i(4'hf),
`endif
	.m0_cyc_i(cpuibus_cyc),
	.m0_stb_i(cpuibus_stb),
	.m0_ack_o(cpuibus_ack),
	// Master 1
	.m1_dat_i(cpudbus_dat_w),
	.m1_dat_o(cpudbus_dat_r),
	.m1_adr_i(cpudbus_adr),
	.m1_cti_i(cpudbus_cti),
	.m1_we_i(cpudbus_we),
	.m1_sel_i(cpudbus_sel),
	.m1_cyc_i(cpudbus_cyc),
	.m1_stb_i(cpudbus_stb),
	.m1_ack_o(cpudbus_ack),
	// Master 2
	.m2_dat_i(32'bx),
	.m2_dat_o(),
	.m2_adr_i(32'bx),
	.m2_cti_i(3'bx),
	.m2_we_i(1'bx),
	.m2_sel_i(4'bx),
	.m2_cyc_i(1'b0),
	.m2_stb_i(1'b0),
	.m2_ack_o(),
	// Master 3
	.m3_dat_i(32'bx),
	.m3_dat_o(),
	.m3_adr_i(32'bx),
	.m3_cti_i(3'bx),
	.m3_we_i(1'bx),
	.m3_sel_i(4'bx),
	.m3_cyc_i(1'b0),
	.m3_stb_i(1'b0),
	.m3_ack_o(),
	// Master 4
	.m4_dat_i(32'bx),
	.m4_dat_o(),
	.m4_adr_i(32'bx),
	.m4_cti_i(3'bx),
	.m4_we_i(1'bx),
	.m4_sel_i(4'bx),
	.m4_cyc_i(1'b0),
	.m4_stb_i(1'b0),
	.m4_ack_o(),

	// Slave 0
	.s0_dat_i(norflash_dat_r),
	.s0_dat_o(norflash_dat_w),
	.s0_adr_o(norflash_adr),
	.s0_cti_o(),
	.s0_sel_o(norflash_sel),
	.s0_we_o(norflash_we),
	.s0_cyc_o(norflash_cyc),
	.s0_stb_o(norflash_stb),
	.s0_ack_i(norflash_ack),
	// Slave 1
	.s1_dat_i(monitor_dat_r),
	.s1_dat_o(monitor_dat_w),
	.s1_adr_o(monitor_adr),
	.s1_cti_o(),
	.s1_sel_o(monitor_sel),
	.s1_we_o(monitor_we),
	.s1_cyc_o(monitor_cyc),
	.s1_stb_o(monitor_stb),
	.s1_ack_i(monitor_ack),
	// Slave 2
	.s2_dat_i(namuru_dat_r),
	.s2_dat_o(namuru_dat_w),
	.s2_adr_o(namuru_adr),
	.s2_cti_o(),
	.s2_sel_o(namuru_sel),
	.s2_we_o(namuru_we),
	.s2_cyc_o(namuru_cyc),
	.s2_stb_o(namuru_stb),
	.s2_ack_i(namuru_ack),
	// Slave 3
	.s3_dat_i(eth_dat_r),
	.s3_dat_o(eth_dat_w),
	.s3_adr_o(eth_adr),
	.s3_cti_o(),
	.s3_sel_o(eth_sel),
	.s3_we_o(eth_we),
	.s3_cyc_o(eth_cyc),
	.s3_stb_o(eth_stb),
	.s3_ack_i(eth_ack),
	// Slave 4
	.s4_dat_i(brg_dat1_r),
	.s4_dat_o(brg_dat1_w),
	.s4_adr_o(brg_adr1),
	.s4_cti_o(brg_cti1),
	.s4_sel_o(brg_sel1),
	.s4_we_o(brg_we1),
	.s4_cyc_o(brg_cyc1),
	.s4_stb_o(brg_stb1),
	.s4_ack_i(brg_ack1),
	// Slave 5
	.s5_dat_i(csrbrg_dat_r),
	.s5_dat_o(csrbrg_dat_w),
	.s5_adr_o(csrbrg_adr),
	.s5_cti_o(),
	.s5_sel_o(),
	.s5_we_o(csrbrg_we),
	.s5_cyc_o(csrbrg_cyc),
	.s5_stb_o(csrbrg_stb),
	.s5_ack_i(csrbrg_ack)
);

//------------------------------------------------------------------
// CSR bus
//------------------------------------------------------------------
wire [13:0]	csr_a;
wire		csr_we;
wire [31:0]	csr_dw;
wire [31:0]	csr_dr_uart,
		csr_dr_sysctl,
		csr_dr_hpdmc,
		csr_dr_ethernet,
		csr_dr_fmlmeter;

//------------------------------------------------------------------
// FML master wires
//------------------------------------------------------------------
wire [`SDRAM_DEPTH-1:0]	fml_brg_adr;

wire		fml_brg_stb;

wire		fml_brg_we;

wire		fml_brg_ack;

wire [7:0]	fml_brg_sel;

wire [63:0]	fml_brg_dw;

wire [63:0]	fml_brg_dr;

//------------------------------------------------------------------
// FML slave wires, to memory controller
//------------------------------------------------------------------
wire [`SDRAM_DEPTH-1:0] fml_adr;
wire fml_stb;
wire fml_we;
wire fml_ack;
wire [7:0] fml_sel;
wire [63:0] fml_dw;
wire [63:0] fml_dr;

//---------------------------------------------------------------------------
// FML arbiter
//---------------------------------------------------------------------------
fmlarb #(
	.fml_depth(`SDRAM_DEPTH)
) fmlarb (
	.sys_clk(sys_clk100),
	.sys_rst(sys_rst),
	
	/* VGA framebuffer (high priority) */
	.m0_adr({`SDRAM_DEPTH'bx}),
	.m0_stb(1'b0),
	.m0_we(1'bx),
	.m0_ack(),
	.m0_sel(8'bx),
	.m0_di(64'bx),
	.m0_do(),

	/* WISHBONE bridge */
	.m1_adr(fml_brg_adr),
	.m1_stb(fml_brg_stb),
	.m1_we(fml_brg_we),
	.m1_ack(fml_brg_ack),
	.m1_sel(fml_brg_sel),
	.m1_di(fml_brg_dw),
	.m1_do(fml_brg_dr),

	/* TMU, pixel read DMA (texture) */
	/* Also used as memory test port */
	.m2_adr({`SDRAM_DEPTH'bx}),
	.m2_stb(1'b0),
	.m2_we(1'bx),
	.m2_ack(),
	.m2_sel(8'bx),
	.m2_di(64'bx),
	.m2_do(),

	/* TMU, pixel write DMA */
	.m3_adr({`SDRAM_DEPTH'bx}),
	.m3_stb(1'b0),
	.m3_we(1'bx),
	.m3_ack(),
	.m3_sel(8'bx),
	.m3_di(64'bx),
	.m3_do(),

	/* TMU, pixel read DMA (destination) */
	.m4_adr({`SDRAM_DEPTH'bx}),
	.m4_stb(1'b0),
	.m4_we(1'bx),
	.m4_ack(),
	.m4_sel(8'bx),
	.m4_di(64'bx),
	.m4_do(fml_tmudr_dr),

	/* Video in */
	.m5_adr({`SDRAM_DEPTH'bx}),
	.m5_stb(1'b0),
	.m5_we(1'bx),
	.m5_ack(),
	.m5_sel(8'bx),
	.m5_di(64'bx),
	.m5_do(),

	.s_adr(fml_adr),
	.s_stb(fml_stb),
	.s_we(fml_we),
	.s_ack(fml_ack),
	.s_sel(fml_sel),
	.s_di(fml_dr),
	.s_do(fml_dw)
);
wire [15:0] csr_a1 = {csr_a,2'b0};

//---------------------------------------------------------------------------
// WISHBONE to CSR bridge
//---------------------------------------------------------------------------
csrbrg csrbrg(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.wb_adr_i(csrbrg_adr),
	.wb_dat_i(csrbrg_dat_w),
	.wb_dat_o(csrbrg_dat_r),
	.wb_cyc_i(csrbrg_cyc),
	.wb_stb_i(csrbrg_stb),
	.wb_we_i(csrbrg_we),
	.wb_ack_o(csrbrg_ack),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_do(csr_dw),
	/* combine all slave->master data lines with an OR */
	.csr_di(
		 csr_dr_uart
		|csr_dr_sysctl
		|csr_dr_hpdmc
		|csr_dr_ethernet
		|csr_dr_fmlmeter
	)
);

//---------------------------------------------------------------------------
// WISHBONE asynchronous bridge
//---------------------------------------------------------------------------
  wb_abrg brg2 (
    .sys_rst (sys_rst),

    // Wishbone slave interface
    .wbs_clk_i (en50),
    .wbs_adr_i (brg_adr1),
    .wbs_dat_i (brg_dat1_w),
    .wbs_dat_o (brg_dat1_r),
    .wbs_sel_i (brg_sel1),
    .wbs_cti_i (brg_cti1),
    .wbs_stb_i (brg_stb1),
    .wbs_cyc_i (brg_cyc1),
    .wbs_we_i  (brg_we1),
    .wbs_ack_o (brg_ack1),

    // Wishbone master interface
    .wbm_clk_i (sys_clk100),
    .wbm_adr_o (brg_adr),
    .wbm_dat_o (brg_dat_w),
    .wbm_dat_i (brg_dat_r),
    .wbm_sel_o (brg_sel),
    .wbm_cti_o (brg_cti),
    .wbm_stb_o (brg_stb),
    .wbm_cyc_o (brg_cyc),
    .wbm_we_o  (brg_we),
    .wbm_ack_i (brg_ack)
  );

//---------------------------------------------------------------------------
// WISHBONE to FML bridge
//---------------------------------------------------------------------------
wire dcb_stb;
wire [`SDRAM_DEPTH-1:0] dcb_adr;
wire [63:0] dcb_dat;
wire dcb_hit;

fmlbrg #(
	.fml_depth(`SDRAM_DEPTH)
) fmlbrg (
	.sys_clk(sys_clk100),
	.sys_rst(sys_rst),
	
	.wb_adr_i(brg_adr),
	.wb_cti_i(brg_cti),
	.wb_dat_o(brg_dat_r),
	.wb_dat_i(brg_dat_w),
	.wb_sel_i(brg_sel),
	.wb_stb_i(brg_stb),
	.wb_cyc_i(brg_cyc),
	.wb_ack_o(brg_ack),
	.wb_we_i(brg_we),
	
	.fml_adr(fml_brg_adr),
	.fml_stb(fml_brg_stb),
	.fml_we(fml_brg_we),
	.fml_ack(fml_brg_ack),
	.fml_sel(fml_brg_sel),
	.fml_di(fml_brg_dr),
	.fml_do(fml_brg_dw),
	
	.dcb_stb(dcb_stb),
	.dcb_adr(dcb_adr),
	.dcb_dat(dcb_dat),
	.dcb_hit(dcb_hit)
);

//---------------------------------------------------------------------------
// Interrupts
//---------------------------------------------------------------------------
wire uart_irq;
wire gpio_irq;
wire timer0_irq;
wire timer1_irq;
wire ethernetrx_irq;
wire ethernettx_irq;
wire namuru_irq;
wire usb_irq;

wire [31:0] cpu_interrupt;

assign cpu_interrupt = {16'd0,
	~namuru_irq,//namuru_irq,
	1'b0,//ir_irq,
	1'b0,//midi_irq,
	1'b0,//videoin_irq,
	ethernettx_irq,
	ethernetrx_irq,
	1'b0,//tmu_irq,
	1'b0,//pfpu_irq,
	1'b0,//ac97dmaw_irq,
	1'b0,//ac97dmar_irq,
	1'b0,//ac97crreply_irq,
	1'b0,//ac97crrequest_irq,
	timer1_irq,
	timer0_irq,
	gpio_irq,
	uart_irq
};

//---------------------------------------------------------------------------
// LM32 CPU
//---------------------------------------------------------------------------
wire bus_errors_en;
wire cpuibus_err;
wire cpudbus_err;
`ifdef CFG_BUS_ERRORS_ENABLED
// Catch NULL pointers and similar errors
// NOTE: ERR is asserted at the same time as ACK, which violates
// Wishbone rule 3.45. But LM32 doesn't care.
reg locked_addr_i;
reg locked_addr_d;
always @(posedge sys_clk) begin
	locked_addr_i <= cpuibus_adr[31:18] == 14'd0;
	locked_addr_d <= cpudbus_adr[31:18] == 14'd0;
end
assign cpuibus_err = bus_errors_en & locked_addr_i & cpuibus_ack;
assign cpudbus_err = bus_errors_en & locked_addr_d & cpudbus_ack;
`else
assign cpuibus_err = 1'b0;
assign cpudbus_err = 1'b0;
`endif

wire ext_break;
lm32_top cpu(
	.clk_i(sys_clk),
	.rst_i(sys_rst),
	.interrupt(cpu_interrupt),

	.I_ADR_O(cpuibus_adr),
	.I_DAT_I(cpuibus_dat_r),
`ifdef CFG_HW_DEBUG_ENABLED
	.I_DAT_O(cpuibus_dat_w),
	.I_SEL_O(cpuibus_sel),
`else
	.I_DAT_O(),
	.I_SEL_O(),
`endif
	.I_CYC_O(cpuibus_cyc),
	.I_STB_O(cpuibus_stb),
	.I_ACK_I(cpuibus_ack),
`ifdef CFG_HW_DEBUG_ENABLED
	.I_WE_O(cpuibus_we),
`else
	.I_WE_O(),
`endif
	.I_CTI_O(cpuibus_cti),
	.I_LOCK_O(),
	.I_BTE_O(),
	.I_ERR_I(cpuibus_err),
	.I_RTY_I(1'b0),
`ifdef CFG_EXTERNAL_BREAK_ENABLED
	.ext_break(ext_break),
`endif

	.D_ADR_O(cpudbus_adr),
	.D_DAT_I(cpudbus_dat_r),
	.D_DAT_O(cpudbus_dat_w),
	.D_SEL_O(cpudbus_sel),
	.D_CYC_O(cpudbus_cyc),
	.D_STB_O(cpudbus_stb),
	.D_ACK_I(cpudbus_ack),
	.D_WE_O (cpudbus_we),
	.D_CTI_O(cpudbus_cti),
	.D_LOCK_O(),
	.D_BTE_O(),
	.D_ERR_I(cpudbus_err),
	.D_RTY_I(1'b0)
);

//---------------------------------------------------------------------------
// Boot ROM
//---------------------------------------------------------------------------
wire tflash_we_n;

norflash16 #(
	.adr_width(24),
	.rd_timing(6),
	.wr_timing(14)
) norflash (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.wb_adr_i(norflash_adr),
	.wb_dat_o(norflash_dat_r),
	.wb_dat_i(norflash_dat_w),
	.wb_sel_i(norflash_sel),
	.wb_stb_i(norflash_stb),
	.wb_cyc_i(norflash_cyc),
	.wb_ack_o(norflash_ack),
	.wb_we_i(norflash_we),
	.lcd_e(lcd_e),
	
	.flash_adr(flash_adr),
	.flash_d(flash_d),
	.flash_oe_n(flash_oe_n),
	.flash_we_n(flash_we_n)
);

assign flash_ce_n = norflash_adr[27];
assign lcd_rs     = norflash_adr[2];

//---------------------------------------------------------------------------
// Monitor ROM / RAM
//---------------------------------------------------------------------------
wire debug_write_lock;
`ifdef CFG_ROM_DEBUG_ENABLED
monitor monitor(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.write_lock(debug_write_lock),
	
	.wb_adr_i(monitor_adr),
	.wb_dat_o(monitor_dat_r),
	.wb_dat_i(monitor_dat_w),
	.wb_sel_i(monitor_sel),
	.wb_stb_i(monitor_stb),
	.wb_cyc_i(monitor_cyc),
	.wb_ack_o(monitor_ack),
	.wb_we_i(monitor_we)
);
`else
assign monitor_dat_r = 32'bx;
assign monitor_ack = 1'b0;
`endif

//---------------------------------------------------------------------------
// UART
//---------------------------------------------------------------------------
uart #(
	.csr_addr(4'h0),
	.clk_freq(`CLOCK_FREQUENCY),
	.baud(`BAUD_RATE),
	.break_en_default(1'b1)
) uart (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_uart),
	
	.irq(uart_irq),
	
	.uart_rx(uart_rx),
	.uart_tx(uart_tx),
`ifdef CFG_EXTERNAL_BREAK_ENABLED
	.break(ext_break)
`else
	.break()
`endif
);

//---------------------------------------------------------------------------
// System Controller
//---------------------------------------------------------------------------
wire [13:0] gpio_outputs;
wire [31:0] capabilities;

sysctl #(
	.csr_addr(4'h1),
	.ninputs(8),
	.noutputs(2),
	.clk_freq(`CLOCK_FREQUENCY),
	.systemid(32'h12004D31) /* 1.2.0 final (0) on M1 */
) sysctl (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.gpio_irq(gpio_irq),
	.timer0_irq(timer0_irq),
	.timer1_irq(timer1_irq),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_sysctl),
	
	.gpio_inputs({inpt_01, pcb_revision, btn3, btn2, btn1}),
	.gpio_outputs({led2, led1}),
	
	.debug_write_lock(debug_write_lock),
	.bus_errors_en(bus_errors_en),
	.capabilities(capabilities),
	.hard_reset(hard_reset)
);

gen_capabilities gen_capabilities(
	.capabilities(capabilities)
);

//---------------------------------------------------------------------------
// DDR SDRAM
//---------------------------------------------------------------------------
ddram #(
	.csr_addr(4'h2)
) ddram (
	.sys_clk(sys_clk100),
	.sys_clk_n(sys_clk100_n),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_hpdmc),
	
	.fml_adr(fml_adr),
	.fml_stb(fml_stb),
	.fml_we(fml_we),
	.fml_ack(fml_ack),
	.fml_sel(fml_sel),
	.fml_di(fml_dw),
	.fml_do(fml_dr),
	
	.sdram_clk_p(sdram_clk_p),
	.sdram_clk_n(sdram_clk_n),
	.sdram_cke(sdram_cke),
	.sdram_cs_n(sdram_cs_n),
	.sdram_we_n(sdram_we_n),
	.sdram_cas_n(sdram_cas_n),
	.sdram_ras_n(sdram_ras_n),
	.sdram_dqm(sdram_dm),
	.sdram_adr(sdram_adr),
	.sdram_ba(sdram_ba),
	.sdram_dq(sdram_dq),
	.sdram_dqs(sdram_dqs)
);

//---------------------------------------------------------------------------
// Ethernet
//---------------------------------------------------------------------------
wire phy_tx_clk_b;
BUFG b_phy_tx_clk(
	.I(phy_tx_clk),
	.O(phy_tx_clk_b)
);
wire phy_rx_clk_b;
BUFG b_phy_rx_clk(
	.I(phy_rx_clk),
	.O(phy_rx_clk_b)
);
`ifdef ENABLE_ETHERNET
minimac2 #(
	.csr_addr(4'h8)
) ethernet (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_ethernet),
	
	.irq_rx(ethernetrx_irq),
	.irq_tx(ethernettx_irq),
	
	.wb_adr_i(eth_adr),
	.wb_dat_o(eth_dat_r),
	.wb_dat_i(eth_dat_w),
	.wb_sel_i(eth_sel),
	.wb_stb_i(eth_stb),
	.wb_cyc_i(eth_cyc),
	.wb_ack_o(eth_ack),
	.wb_we_i(eth_we),
	
	.phy_tx_clk(phy_tx_clk_b),
	.phy_tx_data(phy_tx_data),
	.phy_tx_en(phy_tx_en),
	.phy_tx_er(phy_tx_er),
	.phy_rx_clk(phy_rx_clk_b),
	.phy_rx_data(phy_rx_data),
	.phy_dv(phy_dv),
	.phy_rx_er(phy_rx_er),
	.phy_col(1'b0),
	.phy_crs(1'b0),
	//.phy_col(phy_col),
	//.phy_crs(phy_crs),
	.phy_mii_clk(phy_mii_clk),
	.phy_mii_data(phy_mii_data)
);
`else
assign csr_dr_ethernet = 32'd0;
assign eth_dat_r = 32'bx;
assign eth_ack = 1'b0;
assign ethernetrx_irq = 1'b0;
assign ethernettx_irq = 1'b0;
assign phy_tx_data = 4'b0;
assign phy_tx_en = 1'b0;
assign phy_tx_er = 1'b0;
assign phy_mii_clk = 1'b0;
assign phy_mii_data = 1'bz;
`endif

//always @(posedge clk50) phy_clk <= ~phy_clk;

//---------------------------------------------------------------------------
// FastMemoryLink usage and performance meter
//---------------------------------------------------------------------------
`ifdef ENABLE_FMLMETER
fmlmeter #(
	.csr_addr(4'h9)
) fmlmeter (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_fmlmeter),

	.fml_stb(fml_stb),
	.fml_ack(fml_ack)
);
`else
assign csr_dr_fmlmeter = 32'd0;
`endif

//---------------------------------------------------------------------------
// CORRELATOR
//---------------------------------------------------------------------------
`ifdef ENABLE_CORRELATOR

assign accum_int = namuru_irq;

simplified_gps_baseband corr(
	.clk(sys_clk),
	.hw_rstn(~sys_rst),
	
	.sign(sign_i),
	.mag(sign_q),
	
	.wb_adr_i(namuru_adr),
	.wb_dat_o(namuru_dat_r),
	.wb_dat_i(namuru_dat_w),
	.wb_sel_i(namuru_sel),
	.wb_stb_i(namuru_stb),
	.wb_cyc_i(namuru_cyc),
	.wb_ack_o(namuru_ack),
	.wb_we_i(namuru_we),
	
	//.accum_int(accum_int),
	.accum_int(namuru_irq),
	
	.test_point_01(test_point_01),
	.test_point_02(test_point_02),
	.test_point_03(test_point_03),
	.test_point_04(test_point_04),
	.test_point_05(test_point_05)
);

`endif


endmodule
