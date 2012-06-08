module dump_mask_signal (clk, hw_rstn,
	             chip_select, write, read, 
                     address, 
                     write_data, read_data,
                     ch_dump
		     );

  input clk, hw_rstn, chip_select, write, read;
  input [7:0] address;
  input [31:0] write_data;
  input [11:0] ch_dump;
  output reg [31:0] read_data;

  wire rstn;      // software or hardware generated reset.

  wire ch0_dump;  // channel 0 registers
  wire ch1_dump;  // channel 1 registers
  wire ch2_dump;  // channel 2 registers
  wire ch3_dump;  // channel 3 registers
  wire ch4_dump;  // channel 4 registers
  wire ch5_dump;  // channel 5 registers
  wire ch6_dump;  // channel 6 registers
  wire ch7_dump;  // channel 7 registers
  wire ch8_dump;  // channel 8 registers
  wire ch9_dump;  // channel 9 registers
  wire ch10_dump; // channel 10 registers
  wire ch11_dump; // channel 11 registers
  
  // status registers
  reg [11:0] new_data;       // chan0 = bit 0, chan1 = bit 1 etc, cleared on read.
  reg  [11:0] new_data_miss; //[Art] //The same as new_data but used during bus-read process instead of new_data.
  reg  [11:0] new_data_old;  //[Art] //Used to clear new_data bits that are read during bus-read process.

  assign rstn = hw_rstn;// & ~sw_rst;

  assign {ch11_dump, ch10_dump, ch9_dump, ch8_dump, ch7_dump, ch6_dump, ch5_dump, ch4_dump, ch3_dump, ch2_dump, ch1_dump, ch0_dump} = ch_dump;
                       	     
  // address decoder ----------------------------------
	  
  always @ (posedge clk, new_data)
  begin
  if (!hw_rstn)
    begin
    end
  else

    ///new_data_read = 1'b0;
    case (address)
      // status
      8'hE1 : 
      begin // get new_data
        read_data <= {20'h0,new_data}; // one new_data bit per channel, need to pad other bits
      end
      // default
      default : 
      begin
        read_data <= 0;
      end
    endcase // case(address)

  end

  initial begin //For testing only;
    new_data        = 12'b000000000000;
    new_data_miss   = 12'b000000000000;
  end
  
  wire sw_rst        = ( (address == 8'hF0) & (write) & (chip_select) );
  wire new_data_read = ( (address == 8'hE1) & (read)  & (chip_select) );

  /* FSM */
  reg [1:0] state;
  reg [1:0] next_state;
  
  parameter NO_NEW_DATA_READ_STATE	= 2'd0;
  parameter NEW_DATA_READ_STATE		= 2'd1;
  
  always @(posedge clk) 
  begin
    if(!rstn)
      state <= NO_NEW_DATA_READ_STATE;
    else
      state <= next_state;
  end
  
  always @(*) //This process controls the next state.
  begin
    next_state = state;
        
    case(state)
      
      NO_NEW_DATA_READ_STATE: 
      begin
        if (new_data_read) next_state = NEW_DATA_READ_STATE;
      end
      
      NEW_DATA_READ_STATE: 
      begin
        if (!new_data_read)
          next_state = NO_NEW_DATA_READ_STATE;
      end
      
    endcase
  end
  
  always @(*) //This process is responsible for actions in each state.
  begin
    case(state)
  
      NO_NEW_DATA_READ_STATE:
      begin
        if (new_data_read)
        begin
          if (ch0_dump)  new_data_miss[0]  <= 1'b1;
          if (ch1_dump)  new_data_miss[1]  <= 1'b1;
          if (ch2_dump)  new_data_miss[2]  <= 1'b1;
          if (ch3_dump)  new_data_miss[3]  <= 1'b1;
          if (ch4_dump)  new_data_miss[4]  <= 1'b1;
          if (ch5_dump)  new_data_miss[5]  <= 1'b1;
          if (ch6_dump)  new_data_miss[6]  <= 1'b1;
          if (ch7_dump)  new_data_miss[7]  <= 1'b1;
          if (ch8_dump)  new_data_miss[8]  <= 1'b1;
          if (ch9_dump)  new_data_miss[9]  <= 1'b1;
          if (ch10_dump) new_data_miss[10] <= 1'b1;
          if (ch11_dump) new_data_miss[11] <= 1'b1;
          
          new_data_old <= new_data;
        end
        else
        begin
          if (ch0_dump)  new_data[0]  <= 1'b1;
          if (ch1_dump)  new_data[1]  <= 1'b1;
          if (ch2_dump)  new_data[2]  <= 1'b1;
          if (ch3_dump)  new_data[3]  <= 1'b1;
          if (ch4_dump)  new_data[4]  <= 1'b1;
          if (ch5_dump)  new_data[5]  <= 1'b1;
          if (ch6_dump)  new_data[6]  <= 1'b1;
          if (ch7_dump)  new_data[7]  <= 1'b1;
          if (ch8_dump)  new_data[8]  <= 1'b1;
          if (ch9_dump)  new_data[9]  <= 1'b1;
          if (ch10_dump) new_data[10] <= 1'b1;
          if (ch11_dump) new_data[11] <= 1'b1;
          
          new_data_miss <= 12'b000000000000;
        end
      end
      
      NEW_DATA_READ_STATE:
      begin
        if (!new_data_read)
        begin
          if (ch0_dump  | new_data_miss[0])  new_data[0]  <= 1'b1; else if (new_data_old[0])  new_data[0]  <= 1'b0;
          if (ch1_dump  | new_data_miss[1])  new_data[1]  <= 1'b1; else if (new_data_old[1])  new_data[1]  <= 1'b0;
          if (ch2_dump  | new_data_miss[2])  new_data[2]  <= 1'b1; else if (new_data_old[2])  new_data[2]  <= 1'b0;
          if (ch3_dump  | new_data_miss[3])  new_data[3]  <= 1'b1; else if (new_data_old[3])  new_data[3]  <= 1'b0;
          if (ch4_dump  | new_data_miss[4])  new_data[4]  <= 1'b1; else if (new_data_old[4])  new_data[4]  <= 1'b0;
          if (ch5_dump  | new_data_miss[5])  new_data[5]  <= 1'b1; else if (new_data_old[5])  new_data[5]  <= 1'b0;
          if (ch6_dump  | new_data_miss[6])  new_data[6]  <= 1'b1; else if (new_data_old[6])  new_data[6]  <= 1'b0;
          if (ch7_dump  | new_data_miss[7])  new_data[7]  <= 1'b1; else if (new_data_old[7])  new_data[7]  <= 1'b0;
          if (ch8_dump  | new_data_miss[8])  new_data[8]  <= 1'b1; else if (new_data_old[8])  new_data[8]  <= 1'b0;
          if (ch9_dump  | new_data_miss[9])  new_data[9]  <= 1'b1; else if (new_data_old[9])  new_data[9]  <= 1'b0;
          if (ch10_dump | new_data_miss[10]) new_data[10] <= 1'b1; else if (new_data_old[10]) new_data[10] <= 1'b0;
          if (ch11_dump | new_data_miss[11]) new_data[11] <= 1'b1; else if (new_data_old[11]) new_data[11] <= 1'b0;
        end
        else
        begin
          if (ch0_dump)  new_data_miss[0]  <= 1'b1;
          if (ch1_dump)  new_data_miss[1]  <= 1'b1;
          if (ch2_dump)  new_data_miss[2]  <= 1'b1;
          if (ch3_dump)  new_data_miss[3]  <= 1'b1;
          if (ch4_dump)  new_data_miss[4]  <= 1'b1;
          if (ch5_dump)  new_data_miss[5]  <= 1'b1;
          if (ch6_dump)  new_data_miss[6]  <= 1'b1;
          if (ch7_dump)  new_data_miss[7]  <= 1'b1;
          if (ch8_dump)  new_data_miss[8]  <= 1'b1;
          if (ch9_dump)  new_data_miss[9]  <= 1'b1;
          if (ch10_dump) new_data_miss[10] <= 1'b1;
          if (ch11_dump) new_data_miss[11] <= 1'b1;
        end
      end
      
    endcase
  end
  
endmodule // gps_baseband
			 
			 
			 