----------------------------------------------------------------------------------
-- Company: 	BMSTU
-- Engineer: 	Gavrilov A.
-- 
-- Create Date:    12:42:27 01/22/2010 
-- Design Name: 
-- Module Name:    data_packer - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 		This module takes 4 bits as input. It collects during 4 clocks input and then 
--						outputs 16 bits. It also generates write strobe.
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity data_packer is
  port ( clk : in  STD_LOGIC;								-- clock.
         rst : in  STD_LOGIC;								-- reset.
			di  : in  STD_LOGIC_VECTOR(3 downto 0);	-- Data in bits
         do  : out STD_LOGIC_VECTOR (15 downto 0);	-- Data out bits.
         SLWR: out STD_LOGIC;								-- Write strobe out.
			
         FLAGA : in STD_LOGIC;							-- Look at cy7c68013a documentation.
         FLAGB : in STD_LOGIC;							-- Look at cy7c68013a documentation.
         FLAGC : in STD_LOGIC;							-- Look at cy7c68013a documentation.
         IFCLK : in STD_LOGIC;							-- Look at cy7c68013a documentation.
         CLK0  : in STD_LOGIC;							-- Look at cy7c68013a documentation.
         
         SLRD  : out STD_LOGIC;							-- Look at cy7c68013a documentation.
			
			AntFlag_in  : in  STD_LOGIC;					-- Look at MAX2769 documentation.
         LD_in       : in  STD_LOGIC;					-- Look at MAX2769 documentation.
			AntFlag_out : out STD_LOGIC;					-- output signal for LED.
			LD_out      : out STD_LOGIC;					-- output signal for LED.
			
			ref_clk_sel   : in  STD_LOGIC;				-- Select signal for clock source for MAX2769.
			ext_freq_dsbl : out STD_LOGIC;				-- Control signal for clock buffer amplifier.
			TCXO_dsbl     : out STD_LOGIC;				-- Control signal for clock buffer amplifier.
			
			err_out : out STD_LOGIC);						-- Just another LED.
end data_packer;

architecture synth of data_packer is
  type   state_type is (rcv1, rcv2, rcv3, rcv4, rcv5, rcv6, rcv7, rcv8);	--FSM states.
  signal state_reg: state_type := rcv1;
  signal state_next: state_type;					--FSM.
  signal delay_line_reg, delay_line_next: STD_LOGIC_VECTOR(13 downto 0) := (others=>'0');	-- Delay line.
  signal data_out_reg, data_out_next: STD_LOGIC_VECTOR(15 downto 0) := (others=>'0');		-- register for output signal.
begin

  process (clk)
  begin
	 if (clk'event and clk = '1') then
      state_reg      <= state_next;
      delay_line_reg <= delay_line_next;
      data_out_reg   <= data_out_next;
    end if;
  end process;
  
  --Next-state logic.
  --process(state_reg, delay_line_reg, data_out_reg, di)
  process(state_reg, di)
  begin
    state_next      <= state_reg;
    delay_line_next <= delay_line_reg;
	 data_out_next   <= data_out_reg;

    case state_reg is

      
      when rcv1 =>
        state_next <= rcv2;
        --delay_line_next(13 downto 12) <= di(1 downto 0);
        delay_line_next(1 downto 0) <= di(1 downto 0);
        SLWR <= '0';
        
      when rcv2 =>
        state_next <= rcv3;
        --delay_line_next(11 downto 10) <= di(1 downto 0);
        delay_line_next(3 downto 2) <= di(1 downto 0);
        SLWR <= '1';
        
      when rcv3 =>
        state_next <= rcv4;
        --delay_line_next(9 downto 8) <= di(1 downto 0);
        delay_line_next(5 downto 4) <= di(1 downto 0);
        SLWR <= '1';
        
      when rcv4 =>
        state_next <= rcv5;
        --delay_line_next(7 downto 6) <= di(1 downto 0);
        delay_line_next(7 downto 6) <= di(1 downto 0);
        SLWR <= '1';
        
      when rcv5 =>
        state_next <= rcv6;
        --delay_line_next(5 downto 4) <= di(1 downto 0);
        delay_line_next(9 downto 8) <= di(1 downto 0);
        SLWR <= '1';
        
      when rcv6 =>
        state_next <= rcv7;
        --delay_line_next(3 downto 2) <= di(1 downto 0);
        delay_line_next(11 downto 10) <= di(1 downto 0);
        SLWR <= '0';
		  
      when rcv7 =>
        state_next <= rcv8;
        --delay_line_next(1 downto 0) <= di(1 downto 0);
        delay_line_next(13 downto 12) <= di(1 downto 0);
        SLWR <= '0';
        
      when rcv8 =>
        state_next <= rcv1;
		  --data_out_next <= delay_line_reg & di(1 downto 0);
		  data_out_next <= di(1 downto 0) & delay_line_reg;
        SLWR <= '0';
        
    end case;
  
  end process;
  
  do <= data_out_reg;
--  SLWR <= clk;

  SLRD <= '0';
  AntFlag_out 	 <= '0';
  LD_out 		 <= '0';
  ext_freq_dsbl <= '0';
  TCXO_dsbl     <= '0';
  
  
--  AntFlag_out <= AntFlag_in;
--  LD_out      <= LD_in;
  
--  TCXO_dsbl     <= '1' when ref_clk_sel = '0' else '0';
--  ext_freq_dsbl <= '0' when ref_clk_sel = '0' else '1';
  
--  SLRD <= '0';


end synth;

