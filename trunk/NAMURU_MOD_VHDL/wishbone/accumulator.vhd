----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Peter Mumford, UNSW, 2005
--           vhdl author: Artyom Gavrilov.
-- 
-- Create Date:    15:48:27 06/08/2011 
-- Design Name: 
-- Module Name:    accumulator - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: carrier_mix_sign provides the sign.
--              0 for negative, 1 for positive.
--              The three magnitude bits represent the values 1,2,3,6.
--
--              The code is 0 or 1 representing -1 or 1 respectively.
--
--              The multiplication of the carrier_mix and the code
--              is simply the carrier_mix_mag with the sign determined
--              from the multiplication of the carrier_mix sign and the code.
--
-- code              0 0 1 1
-- carrier_mix_sign  0 1 0 1
--                   -------
-- result            1 0 0 1  (0 for -ve, 1 for +ve)
--
-- if (code == carrier_mix_sign) result = 1
-- else result = 0
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

entity accumulator is
    Port ( clk              : in  STD_LOGIC;
           rstn             : in  STD_LOGIC;
           sample_enable    : in  STD_LOGIC;
           code             : in  STD_LOGIC;
           carrier_mix_sign : in  STD_LOGIC;
           carrier_mix_mag  : in  STD_LOGIC_VECTOR (2 downto 0);
           dump_enable      : in  STD_LOGIC;
           accumulation     : out  STD_LOGIC_VECTOR (15 downto 0));
end accumulator;

architecture Behavioral of accumulator is
  signal accum_i: STD_LOGIC_VECTOR(15 downto 0);
--  signal accumulation: STD_LOGIC_VECTOR(15 downto 0);
begin

  process(clk)
  begin
    if (clk'event and clk='1') then
      if (rstn = '0') then
        accumulation <= (others=>'0');
        accum_i <= (others=>'0');
      elsif (dump_enable = '1') then
        accumulation <= accum_i; -- buffer the accumulation...
        accum_i <= (others=>'0'); -- then reset the accumulation.
      elsif (sample_enable = '1') then -- 20 MHz rate. (pay atention! This comment doen't correspond to comment in time_base.vhd!!!)
        if (code = carrier_mix_sign) then
          accum_i <= accum_i + carrier_mix_mag;
        else
          accum_i <= accum_i - carrier_mix_mag;
        end if;
      end if;
    end if;
  end process;

end Behavioral;

