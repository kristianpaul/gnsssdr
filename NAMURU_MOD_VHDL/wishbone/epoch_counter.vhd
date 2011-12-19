----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Peter Mumford, UNSW, 2005
--           vhdl author: Artyom Gavrilov.
-- 
-- Create Date:    16:08:53 06/08/2011 
-- Design Name: 
-- Module Name:    epoch_counter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: C/A code cycles are counted by two counters;
--              the 1ms epoch counter (or cycle counter)
--              and the 20ms epoch counter (or bit counter).
--              The 1ms epoch counter counts C/A code cycles (by
--              counting dump_enable pulses) that occur every 1ms
--              from 0 to 19. This allows the tracking of the bit
--              boundaries in the broadcast message that occur every
--              20ms. Every time this counter rolls over, the 20ms
--              epoch counter increments. The 20ms epoch counter
--              goes from 0 to 49 to allow tracking of the message
--              frame boundary.
--
--              The 1ms epoch count is 5 bits wide.
--              The 20ms count count is 6 bits wide.
--
--              The values are latched into epoch on the tic_enable.
--              The epoch_check is for instantaneous values used for finding
--              message bit flips.
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

entity epoch_counter is
    Port ( clk          : in  STD_LOGIC;
           rstn         : in  STD_LOGIC;
           tic_enable   : in  STD_LOGIC;
           dump_enable  : in  STD_LOGIC;
           epoch_enable : in  STD_LOGIC;
           epoch_load   : in  STD_LOGIC_VECTOR (10 downto 0);
           epoch        : out  STD_LOGIC_VECTOR (10 downto 0);
           epoch_check  : out  STD_LOGIC_VECTOR (10 downto 0));
end epoch_counter;

architecture Behavioral of epoch_counter is
  signal cycle_count: STD_LOGIC_VECTOR(4 downto 0);
  signal bit_count: STD_LOGIC_VECTOR(5 downto 0);
  signal cycle_count_overflow: STD_LOGIC;
begin

-- the 1ms epoch (C/A code cycle) counter.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (rstn = '0') then
        cycle_count <= (others=>'0');
      elsif (epoch_enable = '1') then
        cycle_count <= epoch_load(4 downto 0);
      elsif (dump_enable = '1') then
        if (cycle_count_overflow = '1') then
          cycle_count <= (others=>'0');
        else
          cycle_count <= cycle_count + 1;
        end if;
      end if;
    end if;
  end process;
  
-- look for overflow.
  cycle_count_overflow <= '1' when (cycle_count = 19) else '0'; --check it!
  
-- the 20ms epoch (bit flip) counter.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (rstn = '0') then
        bit_count <= (others=>'0');
      elsif (epoch_enable = '1') then
        bit_count <= epoch_load(10 downto 5);
      elsif ( (cycle_count_overflow = '1') and (dump_enable = '1') ) then
        if (bit_count = 49) then
          bit_count <= (others=>'0');
        else
          bit_count <= bit_count + 1;
        end if;
      end if;
    end if;
  end process;
  
  -- latch the epoch into a register.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (tic_enable = '1') then
        epoch(4 downto 0)  <= cycle_count;
        epoch(10 downto 5) <= bit_count;
      end if;
    end if;
  end process;
  
  process(clk)
  begin
    if (clk'event and clk='1') then
      epoch_check(4 downto 0)  <= cycle_count;
      epoch_check(10 downto 5) <= bit_count;
    end if;
  end process;

end Behavioral;

