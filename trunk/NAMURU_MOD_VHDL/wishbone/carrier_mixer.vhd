----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Peter Mumford, UNSW, 2005
--           vhdl author: Artyom Gavrilov.
-- 
-- Create Date:    15:32:06 06/08/2011 
-- Design Name: 
-- Module Name:    carrier_mixer - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: The IF raw data and carrier are two bit quantities.
--              Each has a sign bit and a mag bit.
--              The IF_mag bit represents the values 1 and 3.
--              The carrier_mag bit represents the values 1 and 2.
--
--              The mix_mag is three bits representing the values 1,2,3,6
--              The mix_sign bit is 0 for negative, 1 for positive.
--
-- truth table
--
-- if_mag       | 0 0 1 1 |
-- carrier_mag  | 0 1 0 1 |
-- output bit:
--            0 | 1 0 1 0 | = not carrier_mag
--
--            1 | 0 1 1 1 | = if_mag or carrier_mag
--            2 | 0 0 0 1 | = if_mag and carrier_mag
-- -------------|---------|
--    value     | 1 2 3 6 |
-- 
-- if_sign      | 0 0 1 1 |  (0 = -ve, 1 = +ve)
-- carrier sign | 0 1 0 1 |
-- output sign:
--              | 1 0 0 1 |  = not( if_sign xor carrier_sign )
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity carrier_mixer is
    Port ( if_sign      : in  STD_LOGIC;
           if_mag       : in  STD_LOGIC;
           carrier_sign : in  STD_LOGIC;
           carrier_mag  : in  STD_LOGIC;
           mix_sign     : out  STD_LOGIC;
           mix_mag      : out  STD_LOGIC_VECTOR (2 downto 0));
end carrier_mixer;

architecture Behavioral of carrier_mixer is
begin

  mix_mag(0) <= not carrier_mag;
  mix_mag(1) <= if_mag or carrier_mag;
  mix_mag(2) <= if_mag and carrier_mag;
  mix_sign   <= (not( if_sign xor carrier_sign ));

end Behavioral;

