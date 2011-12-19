----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Verilog author: Peter Mumford, 2005, UNSW; 
--              vhdl author: Artyom Gavrilov.
-- 
-- Create Date:    13:37:37 06/07/2011 
-- Design Name: 
-- Module Name:    code_gen - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Generate the C/A code early, prompt and late chipping sequence.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--	Copyright (C) 2007  Peter Mumford
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


entity code_gen is
    Port ( clk :            in  STD_LOGIC;
           rstn :           in  STD_LOGIC;
           tic_enable :     in  STD_LOGIC; -- the TIC;
           hc_enable :      in  STD_LOGIC; -- the half chip enable pulse from code_nco;
           prn_key_enable : in  STD_LOGIC; -- pulse to latch in the prn_key and reset the logic (write & chip_select)
           prn_key :        in  STD_LOGIC_VECTOR (9 downto 0); -- 10 bit number used to select satellite PRN code;
           code_slew :      in  STD_LOGIC_VECTOR (10 downto 0); -- number of half chips to delay the C/A code after the next dump_enable;
           slew_enable :    in  STD_LOGIC; -- pulse to set the slew flag (write & chip select);
           dump_enable :    out STD_LOGIC; -- pulse at the begining/end of prompt C/A code cycle;
           code_phase :     out STD_LOGIC_VECTOR (10 downto 0); -- the phase of the C/A code at the TIC;
           early :          out STD_LOGIC; -- half-chip spaced C/A code sequences;
           prompt :         out STD_LOGIC; -- 
           late :           out STD_LOGIC);--
end code_gen;

architecture Behavioral of code_gen is
  signal g1: STD_LOGIC_VECTOR(9 downto 0); -- the g1 shift register;
  signal g1_q: STD_LOGIC; -- output of the g1 shift register;
  signal g2: STD_LOGIC_VECTOR(9 downto 0); -- the g2 shift register;
  signal g2_q: STD_LOGIC; -- output of the g2 shift register;
  signal ca_code: STD_LOGIC; -- the C/A code chip sequence from g1 and g2 shifters;
  signal srq: STD_LOGIC_VECTOR(2 downto 0); -- the output of the chip spreader;
  
  signal fc_enable: STD_LOGIC; -- full-chip enable that drives the g1 and g2 shifters;
  signal dump_enable_local: STD_LOGIC; -- pulse generated at the beginig/end of the prompt C/A code cycle;
  signal hc_count1: STD_LOGIC_VECTOR(10 downto 0); -- counter used for generating the fc_enable and slew logic (max slew 2045);
  
  signal slew: STD_LOGIC_VECTOR(10 downto 0); -- the code_slew latched if the slew_flag is set;
  signal hc_count2: STD_LOGIC_VECTOR(11 downto 0); -- counter for keeping track of the begining/end of C/A code cycle (max count 4091);
  signal max_count2: STD_LOGIC_VECTOR(11 downto 0); -- limit of hc_count2, normally = 2045, but increased when slew delays the C/A code
  
  --signal dump: STD_LOGIC_VECTOR(1 downto 0); -- dump_enable is generated when hc_count2 = 3;
  signal slew_flag: STD_LOGIC; -- slew_flag is set on the slew_enable pulse and cleared on the dump_enable;
  signal slew_trigger: STD_LOGIC; -- triggers the slew event;
  
  signal hc_count3: STD_LOGIC_VECTOR(10 downto 0); -- this counter is reset at the dump_enable, latched into the code_phase on the TIC;
  
  --shift register my implementation.
  signal shft_reg: STD_LOGIC_VECTOR(2 downto 0);
begin

--   // chip spreader: shift register for generating early, prompt and late chips
--   //--------------------------------------------------------------------------
--   // Half a chip separates the early and prompt, and prompt and late codes.
--   lpm_shiftreg sr(
--     .clock(clk),
--     .sclr(prn_key_enable),
--     .enable(hc_enable),
--     .shiftin(ca_code),
--     .q(srq)
--     );
-- defparam   sr.lpm_width= 3;

-- chip spreader: shift register for generating early, prompt and late chips: hdl implementation.
-- Special attention should be paid during verification!!!
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (prn_key_enable = '1') then -- clear register.
		  shft_reg <= (others=>'0');
      elsif (hc_enable = '1') then --make shifting here.
        shft_reg <= shft_reg(1 downto 0) & ca_code;
      end if;
    end if;
  end process;
  srq <= shft_reg;


  -- The G1 shift register.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (prn_key_enable = '1') then -- set up shift register.
        g1_q <= '0';
		  g1 <= "1111111111";
      elsif (fc_enable = '1') then -- run.
        g1_q <= g1(0);
		  g1 <= (g1(7) xor g1(0)) & g1(9 downto 1);
      end if;
    end if;
  end process;

  -- The G2 shift register.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (prn_key_enable = '1') then -- set up shift register.
        g2_q <= '0';
        g2 <= prn_key;
      elsif (fc_enable = '1') then -- run.
        g2_q <= g2(0);
		  g2 <= (g2(8) xor g2(7) xor g2(4) xor g2(2) xor g2(1) xor g2(0)) & g2(9 downto 1);
      end if;
    end if;
  end process;
  
  ca_code <= g1_q xor g2_q;
  
  --assign the early, prompt and late chips, one half chip apart.
  early <= srq(0);
  prompt <= srq(1);
  late <= srq(2);
  
  -- hc_count3 process.
  ---------------------
  -- Counter 3 counts hc_enables, reset on dump_enable.
  -- If there is slew delay this counter will roll over
  -- before the next dump. However, code_phase measurements
  -- are not valid during slewing.
  process(clk)
  begin
    if(clk'event and clk='1') then
      if ( (prn_key_enable = '1') or (dump_enable_local = '1') ) then
        hc_count3 <= (others=>'0');
      elsif (hc_enable = '1') then
        hc_count3 <= hc_count3 + 1;
      end if;
    end if;
  end process;
  
  -- capture the code phase at TIC
  --------------------------------
  -- The code phase is the half-chip count
  -- at the TIC. Half-chips are numbered 0 to 2045.
  -- The code_nco_phase (from the code_nco) provides
  -- the fine (sub half-chip) code phase.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (tic_enable = '1') then
        code_phase <= hc_count3;
      end if;
    end if;
  end process;
  
  -- The full-chip enable generator
  ----------------------------------
  -- Without the code_slew being set
  -- this process just creates the full-chip enable
  -- at half the rate of the half-chip enable.
  -- When the code_slew is set, the fc_enable
  -- is delayed for a number of half-chips.
  process(clk)
  begin
    if(clk'event and clk='1') then
      if (prn_key_enable = '1') then
        hc_count1 <= (others=>'0');
		  fc_enable <= '0';
		  slew <= (others=>'0'); --reset slew;
      else
        if (slew_trigger = '1') then
          slew <= code_slew;
        end if;
        if (hc_enable = '1') then
          if (slew = 0) then --no delay on the code;
            if (hc_count1 = 1) then
              hc_count1 <= (others=>'0');
              fc_enable <= '1'; --create fc_enable pulse;
            else
              hc_count1 <= hc_count1 + 1; --increment count;
            end if;
          else
            slew <= slew - 1; -- decrement count;
          end if;
        else
          fc_enable <= '0';
        end if;
      end if;
    end if;
  end process;
  
  -- The dump_enable generator
  ----------------------------
  -- create the dump_enable
  --
  -- When a slew value (=x) is written to the code_slew register,
  -- the C/A code is delayed x half-chips at the next dump.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (prn_key_enable = '1') then
        dump_enable_local <= '0';
        hc_count2 <= (others=>'0');
        slew_trigger <= '0';
        max_count2 <= std_logic_vector(to_unsigned(2045, 12)); -- normal half-chip count in one C/A cycle; --Check if "std_logic_vector(to_unsigned(2045, 12));" is correct!!!
      elsif (hc_enable = '1') then
        hc_count2 <= hc_count2 + 1;
        if (hc_count2 = 3) then --dump
          dump_enable_local <= '1';
        elsif (hc_count2 = max_count2) then
          hc_count2 <= (others=>'0');
        elsif (hc_count2 = 1) then -- signals the arrival of the first hc_enable;
          if (slew_flag = '1') then -- slew delay.
            slew_trigger <= '1';
            max_count2 <= std_logic_vector(to_unsigned(2045, 12)) + code_slew;
          else
            max_count2 <= std_logic_vector(to_unsigned(2045, 12));
          end if;
        end if;
      else
        dump_enable_local <= '0';
        slew_trigger <= '0';
      end if;
    end if;
  end process;
  
  
  -- slew_flag process
  --------------------
  -- The slew_flag is set on slew_enable and cleared on the dump_enable.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (prn_key_enable = '1') then
        slew_flag <= '0';
      elsif (slew_enable = '1') then
        slew_flag <= '1';
      elsif (dump_enable_local = '1') then
        slew_flag <= '0';
      end if;
    end if;
  end process;
  
  dump_enable <= dump_enable_local;


end Behavioral; --code_gen

