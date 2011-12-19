----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Peter Mumford, UNSW, 2005
--           vhdl author: Artyom Gavrilov.
-- 
-- Create Date:    13:12:49 06/09/2011 
-- Design Name: 
-- Module Name:    time_base - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Generates the TIC (tic_enable), preTIC (pre_tic_enable)
--              ACCUM_INT (accum_enable) and accum_sample_enable.
--
--             The accumulator sample rate is set at 40/7 MHz in this design.
--             The accum_sample_enable pulse is derived from the sample clock
--             driver for the 2015, but is on a different enable phase.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
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

entity time_base is
    Port ( clk :                 in   STD_LOGIC;
           rstn :                in   STD_LOGIC;
           tic_divide :          in   STD_LOGIC_VECTOR (23 downto 0);
           accum_divide :        in   STD_LOGIC_VECTOR (23 downto 0);
           pre_tic_enable :      out  STD_LOGIC; -- to code_nco's;
           tic_enable :          out  STD_LOGIC; -- to code_gen's;
           accum_enable :        out  STD_LOGIC; -- accumulation interrupt;
           accum_sample_enable : out  STD_LOGIC; -- accumulation sampling enable (80/5MHz = 16MHz - front-end clock);
           tic_count :           out  STD_LOGIC_VECTOR (23 downto 0); -- current value of the TIC counter;
           accum_count :         out  STD_LOGIC_VECTOR (23 downto 0));-- current value of the accum counter;
end time_base;

architecture Behavioral of time_base is
  signal sc_q:      STD_LOGIC_VECTOR (3 downto 0):=(others=>'0'); -- ouput of divide by 7 counter
  signal tic_q:     STD_LOGIC_VECTOR (23 downto 0);
  signal accum_q:   STD_LOGIC_VECTOR (23 downto 0);
  signal tic_shift: STD_LOGIC; -- used to delay TIC 1 clock cycles
  
  signal pre_tic_enable_local: STD_LOGIC;
  signal accum_enable_local: STD_LOGIC;
begin

-- divide by 7 for RF front end (GP2015) sample clock
-- 4 bit counter
--   lpm_counter sc(
--		.clock(clk),
--		.sclr(!rstn),
--		.q(sc_q)
--		);
--   defparam 	 sc.lpm_width= 4;
--   defparam 	 sc.lpm_modulus= 7;

--vhdl implementation Altera's megafunction lpm_counter:
  process(clk)
  begin
    if (clk'event and clk='1') then
	   if (rstn = '0') then
        sc_q <= (others=>'0');
      else
        --if (sc_q = 6 ) then
        --if (sc_q = 4 ) then --Art! 12.12.2011!
        if (sc_q = 2 ) then
          sc_q <= (others=>'0');
        else
          sc_q <= sc_q + 1;
        end if;
      end if;
    end if;
  end process;

  ---accum_sample_enable <= '1' when (sc_q = 3) else '0'; -- accumulation sample pulse.
  accum_sample_enable <= '1' when (sc_q = 1) else '0'; -- accumulation sample pulse.
  
  ----------------------------------------------------
  -- generate the tic_enable
  -- 
  -- tic period = (tic_divide + 1) * Clk period
  -- If clocked by GP2015 40HHz:
  -- tic period = (tic_divide + 1) / 40MHz
  -- For default tic period (0.1s) tic_divide = 0x3D08FF
  ------------------------------------------------------   
--   lpm_counter te(
--		  .clock(clk),
--		  .sclr(!rstn),
--		  .sload(pre_tic_enable),
--		  .data(tic_divide),
--		  .q(tic_q)
--		  );
--   defparam 	 te.lpm_direction="DOWN";
--   defparam 	 te.lpm_width=24;

  -- The preTIC comes first latching the code_nco,
  -- followed by the TIC latching everything else.
  -- This is due to the delay between the code_nco phase
  -- and the prompt code.
  ---pre_tic_enable <= '1' when (tic_q = "000000000000000000000000") else '0';
  
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (rstn = '0') then
        tic_q <= (others=>'1');
      else
        if (pre_tic_enable_local = '1') then
          tic_q <= tic_divide;
        elsif (tic_q = 0) then
          tic_q <= (others=>'1');
        else
          tic_q <= tic_q - 1;
        end if;
      end if;
    end if;
  end process;
  
  pre_tic_enable_local <= '1' when (tic_q = 0) else '0';
  pre_tic_enable <= pre_tic_enable_local;
  tic_count <= tic_q;

  --This process shifts pre_tic_enable_local pulse for 1 clock cycle.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (rstn = '0') then
        tic_shift <= '0';
      else
		  tic_shift <= pre_tic_enable_local;
      end if;
    end if;
  end process;
  
  tic_enable <= tic_shift;
  pre_tic_enable <= pre_tic_enable_local;
  
  -----------------------------------------------------------
  -- generate the accum_enable
  -- 
  -- The Accumulator interrupt signal and flag needs to have 
  -- between 0.5 ms and about 1 ms period.
  -- This is to ensure that accumulation data can be read
  -- before it is written over by new data.
  -- The accumulators are asynchronous to each other and have a
  -- dump period of nominally 1ms.
  --
  -- ACCUM_INT period = (accum_divide + 1) / 40MHz
  -- For 0.5 ms accumulator interrupt
  -- accum_divide = 40000000 * 0.0005 - 1
  -- accum_divide = 0x4E1F	     
  ------------------------------------------------------------
--   lpm_counter ae(
--		  .clock(clk),
--		  .sclr(!rstn),
--		  .sload(accum_enable),
--		  .data(accum_divide),
--		  .q(accum_q)
--		  );
--   defparam 	 ae.lpm_direction="DOWN";
--   defparam 	 ae.lpm_width=24;

  process(clk)
  begin
    if (clk'event and clk='1') then
      if (rstn = '0') then
        accum_q <= (others=>'1');
      else
        if (accum_enable_local = '1') then
          accum_q <= accum_divide;
        elsif (accum_q = 0) then
          accum_q <= (others=>'1');
        else
          accum_q <= accum_q - 1;
        end if;
      end if;
    end if;
  end process;

  accum_enable_local <= '1' when (accum_q = 0) else '0';
  accum_enable <= accum_enable_local;
  accum_count <= accum_q;


end Behavioral;

