/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012
*/

module simplified_gps_baseband (clk, hw_rstn,
                                //input from front-end:
                                sign, mag,
                                //wishbone bus:
                                wb_adr_i, wb_dat_o, wb_dat_i,
                                wb_sel_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_we_i,
                                //interrupt for mcu:
                                accum_int,
                                //test points for FPGA:
                                test_point_01, test_point_02, test_point_03,
                                test_point_04, test_point_05,
                                test_point_001, test_point_002, test_point_003
		            );

   input clk, hw_rstn;
   input sign, mag; // raw data in from RF front end
   input [31:0] wb_adr_i, wb_dat_i;//, wb_dat_o;
   input [3:0] wb_sel_i;
   input wb_stb_i, wb_cyc_i, wb_we_i;
   
   output reg accum_int; // interrupt pulse to tell FW to collect accumulation data, cleared on STATUS read
   output reg [31:0] wb_dat_o;
   output reg wb_ack_o;
   output test_point_01, test_point_02, test_point_03;
   output test_point_04, test_point_05;
   output reg [31:0] test_point_001, test_point_002, test_point_003;

   wire accum_enable_s;
   wire pre_tic_enable, tic_enable, accum_sample_enable;

   wire [23:0] tic_count;
   wire [23:0] accum_count;

   reg sw_rst; // reset to tracking module
   wire rstn; // software generated reset  

   // channel 0 registers
   reg [9:0] ch0_prn_key;
   reg [28:0] ch0_carr_nco;
   reg [27:0] ch0_code_nco;
   reg [10:0] ch0_code_slew;
   reg [10:0] ch0_epoch_load;
   reg ch0_prn_key_enable, ch0_slew_enable, ch0_epoch_enable;
   wire ch0_dump;
   //wire [31:0] ch0_i_early, ch0_q_early, ch0_i_prompt, ch0_q_prompt, ch0_i_late, ch0_q_late;
   wire [15:0] ch0_i_early, ch0_q_early, ch0_i_prompt, ch0_q_prompt, ch0_i_late, ch0_q_late;
   wire [31:0] ch0_carrier_val;
   wire [20:0] ch0_code_val;
   wire [10:0] ch0_epoch, ch0_epoch_check;
   //test_points
   wire ch0_test_point_01, ch0_test_point_02, ch0_test_point_03;
     
   // status registers
   reg [1:0] status; 	// TIC = bit 0, ACCUM_INT = bit 1, cleared on read
   reg status_read; 	// pulse when status register is read
   reg new_data; 		// chan0 = bit 0, chan1 = bit 1 etc, cleared on read
   reg new_data_read;	// pules when new_data register is read
   reg dump_mask;		// mask a channel that has a dump aligned with the new data read
   reg dump_mask_2;		// mask for two clock cycles

   // control registers
   reg [23:0] prog_tic;
   reg [23:0] prog_accum_int;
   
   //memory for testing wishbone-interface:
   reg [31:0] test_memory [0:7];	//eight 32-bit-wide words;

   // connect up time base
   time_base tb (.clk(clk), .rstn(rstn),
		 .tic_divide(prog_tic),
		 .accum_divide(prog_accum_int),
		 .pre_tic_enable(pre_tic_enable),
		 .tic_enable(tic_enable),
		 .accum_enable(accum_enable_s),
		 .accum_sample_enable(accum_sample_enable),
		 .tic_count(tic_count),
		 .accum_count(accum_count)
		 );
   
   assign rstn = hw_rstn & ~sw_rst;
   
   // connect up tracking channels
   tracking_channel tc0 (.clk(clk), .rstn(rstn),
                         .accum_sample_enable(accum_sample_enable),
                         .if_sign(sign), .if_mag(mag),
                         .pre_tic_enable(pre_tic_enable),
                         .tic_enable(tic_enable),
                         .carr_nco_fc(ch0_carr_nco),
                         .code_nco_fc(ch0_code_nco),
                         .prn_key(ch0_prn_key),
                         .prn_key_enable(ch0_prn_key_enable),
                         .code_slew(ch0_code_slew),
                         .slew_enable(ch0_slew_enable),
                         .epoch_enable(ch0_epoch_enable),
	                      .dump(ch0_dump),
	                      .i_early(ch0_i_early),
	                      .q_early(ch0_q_early),
	                      .i_prompt(ch0_i_prompt),
	                      .q_prompt(ch0_q_prompt),
	                      .i_late(ch0_i_late),
	                      .q_late(ch0_q_late),
	                      .carrier_val(ch0_carrier_val),
		                  .code_val(ch0_code_val),
                          .epoch_load(ch0_epoch_load),
	                      .epoch(ch0_epoch),
                          .epoch_check(ch0_epoch_check),
						  .test_point_01(ch0_test_point_01),
						  .test_point_02(ch0_test_point_02),
						  .test_point_03(ch0_test_point_03));
                       	     
   // address decoder ----------------------------------
	  
   always @ (posedge clk)
   begin
   if (!hw_rstn)
      begin
	    // Need to initialize nco's (at least for simulation) or they don't run.
	    ch0_carr_nco <= 0;
	    ch0_code_nco <= 0;
	    // Anything else need initializing here?
      end
   else
   
      sw_rst = 1'b0;
      case (wb_adr_i[9:2])
         // channel 0
         8'h00 : begin
	               ch0_prn_key_enable <= (wb_cyc_i & wb_stb_i & wb_we_i);
	               if (wb_cyc_i & wb_stb_i & wb_we_i) ch0_prn_key <= wb_dat_i[9:0];
	             end
         8'h01 : if (wb_cyc_i & wb_stb_i & wb_we_i) ch0_carr_nco <= wb_dat_i[28:0];
         8'h02 : if (wb_cyc_i & wb_stb_i & wb_we_i) ch0_code_nco <= wb_dat_i[27:0];
         8'h03 : begin
	               ch0_slew_enable <= (wb_cyc_i & wb_stb_i & wb_we_i);
	               if (wb_cyc_i & wb_stb_i & wb_we_i) ch0_code_slew <= wb_dat_i[10:0];
	             end
         8'h04 : wb_dat_o <= {16'h0, ch0_i_early};
         8'h05 : wb_dat_o <= {16'h0, ch0_q_early};			 
         8'h06 : wb_dat_o <= {16'h0, ch0_i_prompt};			 
         8'h07 : wb_dat_o <= {16'h0, ch0_q_prompt};   	      		 
         8'h08 : wb_dat_o <= {16'h0, ch0_i_late};			 
         8'h09 : wb_dat_o <= {16'h0, ch0_q_late};   
         8'h0A : wb_dat_o <= ch0_carrier_val;			// 32 bits
         8'h0B : wb_dat_o <= {11'h0, ch0_code_val};		// 21 bits
         8'h0C : wb_dat_o <= {21'h0, ch0_epoch};		// 11 bits
         8'h0D : wb_dat_o <= {21'h0, ch0_epoch_check};	// 11 bits
         8'h0E : begin
                   ch0_epoch_enable <= (wb_cyc_i & wb_stb_i & wb_we_i);
                   if (wb_cyc_i & wb_stb_i & wb_we_i) ch0_epoch_load <= wb_dat_i[10:0];
                 end
         
		 
         // For testing wishbone interface:
		 // write to memory:
         8'hC0 : if (wb_cyc_i & wb_stb_i & wb_we_i) test_memory[0] <= wb_dat_i[31:0];
		 8'hC1 : if (wb_cyc_i & wb_stb_i & wb_we_i) test_memory[1] <= wb_dat_i[31:0];
		 8'hC2 : if (wb_cyc_i & wb_stb_i & wb_we_i) test_memory[2] <= wb_dat_i[31:0];
		 8'hC3 : if (wb_cyc_i & wb_stb_i & wb_we_i) test_memory[3] <= wb_dat_i[31:0];
		 8'hC4 : if (wb_cyc_i & wb_stb_i & wb_we_i) test_memory[4] <= wb_dat_i[31:0];
		 8'hC5 : if (wb_cyc_i & wb_stb_i & wb_we_i) test_memory[5] <= wb_dat_i[31:0];
		 8'hC6 : if (wb_cyc_i & wb_stb_i & wb_we_i) test_memory[6] <= wb_dat_i[31:0];
		 8'hC7 : if (wb_cyc_i & wb_stb_i & wb_we_i) test_memory[7] <= wb_dat_i[31:0];
		 // read from memory:
		 8'hD0 : wb_dat_o <= test_memory[0];
		 8'hD1 : wb_dat_o <= test_memory[1];
		 8'hD2 : wb_dat_o <= test_memory[2];
		 8'hD3 : wb_dat_o <= test_memory[3];
		 8'hD4 : wb_dat_o <= test_memory[4];
		 8'hD5 : wb_dat_o <= test_memory[5];
		 8'hD6 : wb_dat_o <= test_memory[6];
		 8'hD7 : wb_dat_o <= test_memory[7];

         // status
         8'hE0 : begin	// get status and pulse status_flag to clear status
                   wb_dat_o <= {30'h0, status}; 					// only 2 status bits, therefore need to pad 30ms bits
	               status_read <= (wb_cyc_i & wb_stb_i);	// pulse status flag to clear status register
	             end
         8'hE1 : begin // get new_data
                   wb_dat_o <= {30'h0, new_data}; // one new_data bit per channel, need to pad other bits
                   // pulse the new data flag to clear new_data register
			       new_data_read <= (wb_cyc_i & wb_stb_i);
			       // make sure the flag is not cleared if a dump is aligned to new_data_read
			       dump_mask <= ch0_dump;
                 end
         8'hE2 : begin // tic count read
                   wb_dat_o <= {8'h0, tic_count}; // 24 bits of TIC count
                 end
         8'hE3 : begin // accum count read
                   wb_dat_o <= {8'h0, accum_count}; // 24 bits of accum count
                 end

         // control
         8'hF0 : sw_rst = (wb_cyc_i & wb_stb_i & wb_we_i); // software reset
         8'hF1 : if (wb_cyc_i & wb_stb_i & wb_we_i) prog_tic <= wb_dat_i[23:0];			// program TIC
         8'hF2 : if (wb_cyc_i & wb_stb_i & wb_we_i) prog_accum_int <= wb_dat_i[23:0];	// program ACCUM_INT
       
         default : wb_dat_o <= 0;

    endcase // case(address)
   end

	always @(posedge clk) 
	begin
		if(!hw_rstn)
			wb_ack_o <= 1'b0;
		else begin
			if(wb_cyc_i & wb_stb_i)
				wb_ack_o <= ~wb_ack_o;
			else
				wb_ack_o <= 1'b0;
		end
	end
   
   // process to create a two clk wide dump_mask pulse
   always @ (posedge clk)
   begin
     if (!rstn)
        dump_mask_2 <= 0;
     else
        dump_mask_2 <= dump_mask;
   end

   // process to reset the status register after a read
   // also create accum_int signal that is cleared after status read
   
   always @ (posedge clk)
   begin
	 if (!rstn || status_read)
	    begin
	      status <= 0;
          accum_int <= 0;
	    end
	 else
      begin
	    if (tic_enable)
	      status[0] <= 1;
	    if (accum_enable_s)
          begin
	        status[1] <= 1;
            accum_int <= 1;
          end
	    end
   end

   // process to reset the new_data register after a read
   // set new data bits when channel dumps occur
   always @ (posedge clk)
   begin
	 if (!rstn || new_data_read)
	    begin
	      new_data <= dump_mask | dump_mask_2;
	    end
	 else
       begin
       if (ch0_dump)
	     new_data <= 1;
       end // else: !if(!rstn || new_data_read)
   end // always @ (posedge clk)
		     
endmodule // gps_baseband
			 
			 
			 
