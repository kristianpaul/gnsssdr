----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Peter Mumford, UNSW, 2005
--           vhdl author: Artyom Gavrilov.
-- 
-- Create Date:    12:03:15 06/09/2011 
-- Design Name: 
-- Module Name:    carrier_nco - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Generates the 8 stage carrier local oscilator.
--
--                 Numerically Controlled Oscillator (NCO) which replicates the
--                 carrier frequency. This pseudo-sinusoid waveform consists of
--                 8 stages or phases.
--
--                 The NCO frequency is:
--                
--                    f = fControl * Clk / 2^N
--                 where:
--                 f = the required carrier wave frequency
--                 Clk = the system clock (= 40MHz)
--                 N = 30 (bit width of the phase accumulator)
--                 fControl = the 30 bit (unsigned) control word 
-- 
--                 The generated waveforms for I & Q look like:
--                 Phase   :  0  1  2  3  4  5  6  7
--                 ---------------------------------
--                        I: -1 +1 +2 +2 +1 -1 -2 -2
--                        Q: +2 +2 +1 -1 -2 -2 -1 +1
--
--                 The nominal center frequency for the GP2015 is:
--                 IF = 1.405396825MHz
--                 Clk = 40 MHz
--                 fControl = 2^N * IF / Clk
--                 fControl = 0x23FA689 for center frequency
--
--                 Resolution:
--                 fControl increment value = 0.037252902 Hz
--                 Put another way:
--                 37mHz is the smallest change in carrier frequency possible
--                 with this NCO.
-- 
--                 The carrier phase and carrier cycle count are latched into
--                 the carrier_val on the tic_enable. The carrier phase is the
--                 10 msb of the accumulator register (accum_reg). The cycle count
--                 is the number of full carrier wave cycles between the last 2
--                 tic_enables. The two values are combined into the carrier_val.
--                 Bits 9:0 are the carrier phase, bits 31:10 are the cycle count.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--  Copyright (C) 2007  Peter Mumford
--
--    This library is free software; you can redistribute it and/or
--    modify it under the terms of the GNU Lesser General Public
--    License as published by the Free Software Foundation; either
--    version 2.1 of the License, or (at your option) any later version.
--
--    This library is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--    Lesser General Public License for more details.
--
--    You should have received a copy of the GNU Lesser General Public
--    License along with this library; if not, write to the Free Software
--    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity carrier_nco is
    Port ( clk :         in  STD_LOGIC;
           rstn :        in  STD_LOGIC;
           tic_enable :  in  STD_LOGIC;
           f_control :   in  STD_LOGIC_VECTOR (28 downto 0);
           carrier_val : out  STD_LOGIC_VECTOR (31 downto 0);
           i_sign :      out  STD_LOGIC;  -- in-phase (cosine) carrier wav;
           i_mag :       out  STD_LOGIC;  -- in-phase (cosine) carrier wav;
           q_sign :      out  STD_LOGIC;  -- quadrature (sine) carrier wave;
           q_mag :       out  STD_LOGIC); -- quadrature (sine) carrier wave;
end carrier_nco;

architecture Behavioral of carrier_nco is
  signal accum_reg : STD_LOGIC_VECTOR (29 downto 0);
  signal cycle_count_reg : STD_LOGIC_VECTOR (21 downto 0);
   
  signal phase_key : STD_LOGIC_VECTOR (3 downto 0);
  signal accum_sum : STD_LOGIC_VECTOR (30 downto 0);
  signal accum_carry : STD_LOGIC ;
  signal combined_carr_value : STD_LOGIC_VECTOR (31 downto 0);
begin

  -- 30 bit phase accumulator.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (rstn = '0') then
        accum_reg <= (others=>'0');
      else
        accum_reg <= accum_sum(29 downto 0);
      end if;
    end if;
  end process;
  
  accum_sum <= ('0' & accum_reg) + f_control; --Check it during verification!!!
  accum_carry <= accum_sum(30);
  phase_key <= accum_sum(29 downto 26);
  
  combined_carr_value(9 downto 0) <= accum_reg(29 downto 20);
  combined_carr_value(31 downto 10) <= cycle_count_reg;
  
  -- cycle counter and value latching.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (rstn = '0') then
        cycle_count_reg <= (others=>'0');
      elsif (tic_enable = '1') then
        carrier_val <= combined_carr_value; --latch in carrier value, then...
        cycle_count_reg <= (others=>'0'); -- reset counter.
      elsif (accum_carry = '1') then
        cycle_count_reg <= cycle_count_reg + 1;
      end if;
    end if;
  end process;
  
  -- look up table for carrier pseudo-sinwave generation.
  process(phase_key)
  begin
    case phase_key is
	   -- 0 0 degrees.
      when "0000" | "1111" =>
        i_sign <= '0';
        i_mag  <= '0';
        q_sign <= '1';
        q_mag  <= '1';
        
      -- 1 45 degrees.
      when "0001" | "0010" =>
        i_sign <= '1';
        i_mag  <= '0';
        q_sign <= '1';
        q_mag  <= '1';
        
      -- 2 90 degrees.
      when "0011" | "0100" =>
        i_sign <= '1';
        i_mag  <= '1';
        q_sign <= '1';
        q_mag  <= '0';
        
      -- 3 135 degrees.
      when "0101" | "0110" =>
        i_sign <= '1';
        i_mag  <= '1';
        q_sign <= '0';
        q_mag  <= '0';
        
      -- 4 180 degrees.
      when "0111" | "1000" =>
        i_sign <= '1';
        i_mag  <= '0';
        q_sign <= '0';
        q_mag  <= '1';
        
      -- 5 225 degrees.
      when "1001" | "1010" =>
        i_sign <= '0';
        i_mag  <= '0';
        q_sign <= '0';
        q_mag  <= '1';
        
      -- 6 270 degrees.
      when "1011" | "1100" =>
        i_sign <= '0';
        i_mag  <= '1';
        q_sign <= '0';
        q_mag  <= '0';
        
      -- 7 315 degrees.
      when others =>
        i_sign <= '0';
        i_mag  <= '1';
        q_sign <= '1';
        q_mag  <= '0';
    end case;
  end process;

end Behavioral;

