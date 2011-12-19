----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Peter Mumford, UNSW, 2005
--           vhdl author: Artyom Gavrilov.
-- 
-- Create Date:    11:36:07 06/09/2011 
-- Design Name: 
-- Module Name:    code_nco - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Generate the half-chip enable signal.
--
--                 The Code_NCO creates the half-chip enable signal.
--                 This drives the C/A code generator at the required frequency
--                 (nominally 1.023MHz). The frequency must be adjusted by the
--                 application code to align the incomming signal with the
--                 generated C/A code replica and to account for clock error
--                 (TCXO frequency error) and doppler.
--
--                 The code_NCO provides the fine code phase (10 bit) value on
--                 the TIC signal. 
--                 Note 1) The full-chip enable (fc_enable) is generated in the code_gen
--                 module and is not aligned with the hc_enable.
--                 The C/A code chip boundaries align to the fc_enable
--                 not the hc_enable. This implies that the fine code phase obtained
--                 from the code_nco that generates the hc_enable will be early by
--                 one clock cycle. To account for this, the pre_tic_enable is used to
--                 latch the code NCO phase. 
--
--                 The NCO frequency is:
--
--                    f = fControl * clk/2^N
--                 where:
--                 f = the required frequency
--                 N = 29 (bit width of the phase accumulator)
--                 clk = the system clock (= 40MHz)
--                 fControl = the 28 bit (unsigned) control word
-- 
--                 To generate the C/A code at f, the NCO must be set to run
--                 at 2f, therefore:
--                      code_frequency = 0.5 * fControl * clk/2^N
--
--                 For a system clock running @ clk = 40 MHz:
--                     fControl = code_frequency * 2^29 / 20[Mhz]
--
--                 For code_frequency = 1.023MHz
--                     fControl = 0x1A30552
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

entity code_nco is
    Port ( clk :            in  STD_LOGIC;
           rstn :           in  STD_LOGIC;
           tic_enable :     in  STD_LOGIC;
           f_control :      in  STD_LOGIC_VECTOR (27 downto 0);
           hc_enable :      out  STD_LOGIC;
           code_nco_phase : out  STD_LOGIC_VECTOR (9 downto 0));
end code_nco;

architecture Behavioral of code_nco is
  signal accum_reg: STD_LOGIC_VECTOR(28 downto 0);
  signal accum_sum: STD_LOGIC_VECTOR(29 downto 0);
  signal accum_carry: STD_LOGIC;
begin

  -- 29 bit phase accumulator.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (rstn = '0') then
        accum_reg <= (others=>'0');
      else
        accum_reg <= accum_sum(28 downto 0);
      end if;
    end if;
  end process;
  
  accum_sum <= ('0' & accum_reg) + f_control; --!!! check during verification!!!
  accum_carry <= accum_sum(29);
  
  -- latch the top 10 bits on the tic_enable.
  process(clk)
  begin
    if (rstn='0') then
      code_nco_phase <= (others=>'0');
    elsif (tic_enable = '1') then
      code_nco_phase <= accum_reg(28 downto 19); -- see note 1 above.
    end if;
  end process;
  
  -- generate the half-chip enable.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (rstn = '0') then
        hc_enable <= '0';
      elsif (accum_carry = '1') then
        hc_enable <= '1';
      else
        hc_enable <= '0';
      end if;
    end if;
  end process;

end Behavioral;

