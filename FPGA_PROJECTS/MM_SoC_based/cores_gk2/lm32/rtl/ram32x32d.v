`timescale 1 ns / 1 ps
module ram_v32d (clk,  we,  addrw, addrr, di, dow, dor ); // 

  // Registers, nets and parameters

 parameter data_bit = 32;
 parameter adr_bit  = 5;

    input             clk;
    input             we;
    input      [adr_bit-1:0] addrw;
    input      [adr_bit-1:0] addrr;
    input      [data_bit-1:0] di;
    output     [data_bit-1:0] dow;
    output     [data_bit-1:0] dor;
	
wire we0,we1;   
wire [data_bit-1:0] dor0,dor1;   
wire [data_bit-1:0] dow0,dow1;   

assign we0=we & ~addrw[4];
assign we1=we &  addrw[4];
//============================================================================

 RAM16X1D   
  RAM16X1D_00 (
  .DPO(dor0[0]),.SPO(dow0[0]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[0]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  ); 
  
 RAM16X1D   
  RAM16X1D_01 (
  .DPO(dor0[1]),.SPO(dow0[1]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[1]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_02 (
  .DPO(dor0[2]),.SPO(dow0[2]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[2]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_03 (
  .DPO(dor0[3]),.SPO(dow0[3]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[3]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_04 (
  .DPO(dor0[4]),.SPO(dow0[4]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[4]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_05 (
  .DPO(dor0[5]),.SPO(dow0[5]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[5]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_06 (
  .DPO(dor0[6]),.SPO(dow0[6]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[6]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_07 (
  .DPO(dor0[7]),.SPO(dow0[7]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[7]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );
 
RAM16X1D    RAM16X1D_08 (
  .DPO(dor0[8]),.SPO(dow0[8]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[8]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_09 (
  .DPO(dor0[9]),.SPO(dow0[9]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[9]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_010 (
  .DPO(dor0[10]),.SPO(dow0[10]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[10]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_011 (
  .DPO(dor0[11]),.SPO(dow0[11]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[11]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_012 (
  .DPO(dor0[12]),.SPO(dow0[12]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[12]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_013 (
  .DPO(dor0[13]),.SPO(dow0[13]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[13]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_014 (
  .DPO(dor0[14]),.SPO(dow0[14]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[14]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_015 (
  .DPO(dor0[15]),.SPO(dow0[15]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[15]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );

RAM16X1D    RAM16X1D_16 (
  .DPO(dor0[16]),.SPO(dow0[16]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[16]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_17 (
  .DPO(dor0[17]),.SPO(dow0[17]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[17]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_18 (
  .DPO(dor0[18]),.SPO(dow0[18]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[18]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_19 (
  .DPO(dor0[19]),.SPO(dow0[19]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[19]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_20 (
  .DPO(dor0[20]),.SPO(dow0[20]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[20]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_21 (
  .DPO(dor0[21]),.SPO(dow0[21]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[21]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_22 (
  .DPO(dor0[22]),.SPO(dow0[22]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[22]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_23 (
  .DPO(dor0[23]),.SPO(dow0[23]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[23]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );

RAM16X1D    RAM16X1D_24 (
  .DPO(dor0[24]),.SPO(dow0[24]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[24]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_25 (
  .DPO(dor0[25]),.SPO(dow0[25]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[25]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_26 (
  .DPO(dor0[26]),.SPO(dow0[26]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[26]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_27 (
  .DPO(dor0[27]),.SPO(dow0[27]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[27]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_28 (
  .DPO(dor0[28]),.SPO(dow0[28]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[28]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_29 (
  .DPO(dor0[29]),.SPO(dow0[29]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[29]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_30 (
  .DPO(dor0[30]),.SPO(dow0[30]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[30]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );   
 RAM16X1D    RAM16X1D_31 (
  .DPO(dor0[31]),.SPO(dow0[31]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[31]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we0)  );
//============================================================================
 RAM16X1D    RAM16X1D_100 (
  .DPO(dor1[0]),.SPO(dow1[0]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[0]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_101 (
  .DPO(dor1[1]),.SPO(dow1[1]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[1]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_102 (
  .DPO(dor1[2]),.SPO(dow1[2]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[2]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_103 (
  .DPO(dor1[3]),.SPO(dow1[3]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[3]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_104 (
  .DPO(dor1[4]),.SPO(dow1[4]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[4]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_105 (
  .DPO(dor1[5]),.SPO(dow1[5]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[5]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_106 (
  .DPO(dor1[6]),.SPO(dow1[6]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[6]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_107 (
  .DPO(dor1[7]),.SPO(dow1[7]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[7]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );
 
RAM16X1D    RAM16X1D_108 (
  .DPO(dor1[8]),.SPO(dow1[8]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[8]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_109 (
  .DPO(dor1[9]),.SPO(dow1[9]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[9]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_110 (
  .DPO(dor1[10]),.SPO(dow1[10]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[10]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_111 (
  .DPO(dor1[11]),.SPO(dow1[11]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[11]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_112 (
  .DPO(dor1[12]),.SPO(dow1[12]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[12]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_113 (
  .DPO(dor1[13]),.SPO(dow1[13]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[13]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_114 (
  .DPO(dor1[14]),.SPO(dow1[14]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[14]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_115 (
  .DPO(dor1[15]),.SPO(dow1[15]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[15]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );

RAM16X1D    RAM16X1D_116 (
  .DPO(dor1[16]),.SPO(dow1[16]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[16]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_117 (
  .DPO(dor1[17]),.SPO(dow1[17]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[17]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_118 (
  .DPO(dor1[18]),.SPO(dow1[18]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[18]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_119 (
  .DPO(dor1[19]),.SPO(dow1[19]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[19]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_120 (
  .DPO(dor1[20]),.SPO(dow1[20]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[20]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_121 (
  .DPO(dor1[21]),.SPO(dow1[21]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[21]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_122 (
  .DPO(dor1[22]),.SPO(dow1[22]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[22]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_123 (
  .DPO(dor1[23]),.SPO(dow1[23]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[23]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );

RAM16X1D    RAM16X1D_124 (
  .DPO(dor1[24]),.SPO(dow1[24]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[24]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_125 (
  .DPO(dor1[25]),.SPO(dow1[25]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[25]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_126 (
  .DPO(dor1[26]),.SPO(dow1[26]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[26]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_127 (
  .DPO(dor1[27]),.SPO(dow1[27]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[27]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_128 (
  .DPO(dor1[28]),.SPO(dow1[28]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[28]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_129 (
  .DPO(dor1[29]),.SPO(dow1[29]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[29]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_130 (
  .DPO(dor1[30]),.SPO(dow1[30]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[30]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );   
 RAM16X1D    RAM16X1D_131 (
  .DPO(dor1[31]),.SPO(dow1[31]),.A0(addrw[0]),.A1(addrw[1]),.A2(addrw[2]),.A3(addrw[3]),.D(di[31]),
  .DPRA0(addrr[0]),.DPRA1(addrr[1]),.DPRA2(addrr[2]),.DPRA3(addrr[3]),.WCLK(clk),.WE(we1)  );
   
//==============================================================================	   
assign   dow = addrw[4] ? dow1:dow0;
assign   dor = addrr[4] ? dor1:dor0;
	   
	   
endmodule
