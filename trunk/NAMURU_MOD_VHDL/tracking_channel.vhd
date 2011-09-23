----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Peter Mumford, UNSW, 2005
--           vhdl author: Artyom Gavrilov.
-- 
-- Create Date:    15:03:28 06/09/2011 
-- Design Name: 
-- Module Name:    tracking_channel - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Wire the correlator block together:
--               2 carrier_mixers
--               1 carrier_nco
--               1 code_nco
--               1 code_gen
--               1 epoch_counter
--               6 accumulators
--
-- Artyom Gavrilov additions: convert from I-channel only to I/Q-channels input!
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tracking_channel is
    Port ( clk :                 in  STD_LOGIC;
           rstn :                in  STD_LOGIC;
           accum_sample_enable : in  STD_LOGIC;
           if_sign_i :           in  STD_LOGIC;
           if_mag_i :            in  STD_LOGIC;
           if_sign_q :           in  STD_LOGIC;
           if_mag_q :            in  STD_LOGIC;
           pre_tic_enable :      in  STD_LOGIC;
           tic_enable :          in  STD_LOGIC;
           carr_nco_fc :         in  STD_LOGIC_VECTOR (28 downto 0);
           code_nco_fc :         in  STD_LOGIC_VECTOR (27 downto 0);
           prn_key :             in  STD_LOGIC_VECTOR (9 downto 0);
           prn_key_enable :      in  STD_LOGIC;
           code_slew :           in  STD_LOGIC_VECTOR (10 downto 0);
           slew_enable :         in  STD_LOGIC;
           epoch_enable :        in  STD_LOGIC;
           dump :                out STD_LOGIC;
           i_early :             out STD_LOGIC_VECTOR (15 downto 0);
           q_early :             out STD_LOGIC_VECTOR (15 downto 0);
           i_prompt :            out STD_LOGIC_VECTOR (15 downto 0);
           q_prompt :            out STD_LOGIC_VECTOR (15 downto 0);
           i_late :              out STD_LOGIC_VECTOR (15 downto 0);
           q_late :              out STD_LOGIC_VECTOR (15 downto 0);
           carrier_val :         out STD_LOGIC_VECTOR (31 downto 0);
           code_val :            out STD_LOGIC_VECTOR (20 downto 0);
           epoch_load :          in  STD_LOGIC_VECTOR (10 downto 0);
           epoch :               out STD_LOGIC_VECTOR (10 downto 0);
           epoch_check :         out STD_LOGIC_VECTOR (10 downto 0);
           test_point_01:        out STD_LOGIC;
           test_point_02:        out STD_LOGIC;
           test_point_03:        out STD_LOGIC);
end tracking_channel;

architecture Behavioral of tracking_channel is
  signal carrier_i_sign, carrier_q_sign: STD_LOGIC;
  signal carrier_i_mag, carrier_q_mag: STD_LOGIC;
  signal mix_i_sign, mix_q_sign: STD_LOGIC;
  signal mix_i_mag, mix_q_mag: STD_LOGIC_VECTOR (2 downto 0);
  signal hc_enable, dump_enable: STD_LOGIC;
  signal early_code, prompt_code, late_code: STD_LOGIC;

  component carrier_mixer
    port ( if_sign      : in  STD_LOGIC;
           if_mag       : in  STD_LOGIC;
           carrier_sign : in  STD_LOGIC;
           carrier_mag  : in  STD_LOGIC;
           mix_sign     : out  STD_LOGIC;
           mix_mag      : out  STD_LOGIC_VECTOR (2 downto 0));
  end component;
  
  component carrier_nco 
    port ( clk :         in  STD_LOGIC;
           rstn :        in  STD_LOGIC;
           tic_enable :  in  STD_LOGIC;
           f_control :   in  STD_LOGIC_VECTOR (28 downto 0);
           carrier_val : out  STD_LOGIC_VECTOR (31 downto 0);
           i_sign :      out  STD_LOGIC;  -- in-phase (cosine) carrier wav;
           i_mag :       out  STD_LOGIC;  -- in-phase (cosine) carrier wav;
           q_sign :      out  STD_LOGIC;  -- quadrature (sine) carrier wave;
           q_mag :       out  STD_LOGIC); -- quadrature (sine) carrier wave;
  end component;
  
  component code_nco
    port ( clk :            in  STD_LOGIC;
           rstn :           in  STD_LOGIC;
           tic_enable :     in  STD_LOGIC;
           f_control :      in  STD_LOGIC_VECTOR (27 downto 0);
           hc_enable :      out  STD_LOGIC;
           code_nco_phase : out  STD_LOGIC_VECTOR (9 downto 0));
  end component;
  
  component code_gen
    port ( clk :            in  STD_LOGIC;
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
  end component;
  
  component epoch_counter
    port ( clk          : in  STD_LOGIC;
           rstn         : in  STD_LOGIC;
           tic_enable   : in  STD_LOGIC;
           dump_enable  : in  STD_LOGIC;
           epoch_enable : in  STD_LOGIC;
           epoch_load   : in  STD_LOGIC_VECTOR (10 downto 0);
           epoch        : out  STD_LOGIC_VECTOR (10 downto 0);
           epoch_check  : out  STD_LOGIC_VECTOR (10 downto 0));
  end component;
  
  component accumulator
    port ( clk              : in  STD_LOGIC;
           rstn             : in  STD_LOGIC;
           sample_enable    : in  STD_LOGIC;
           code             : in  STD_LOGIC;
           carrier_mix_sign : in  STD_LOGIC;
           carrier_mix_mag  : in  STD_LOGIC_VECTOR (2 downto 0);
           dump_enable      : in  STD_LOGIC;
           accumulation     : out  STD_LOGIC_VECTOR (15 downto 0));
  end component;
  
begin

  dump <= dump_enable;
  
  -- carrier mixers-------------------------------------------------
  i_cos: carrier_mixer
    port map(if_sign => if_sign_i, if_mag => if_mag_i, -- raw data input.
             carrier_sign => carrier_i_sign, carrier_mag => carrier_i_mag, -- carrier nco inputs.
             mix_sign => mix_i_sign, mix_mag => mix_i_mag); -- outputs
				 
  q_sin: carrier_mixer
    --port map(if_sign => if_sign_q, if_mag => if_mag_q, -- raw data input.
	 port map(if_sign => if_sign_i, if_mag => if_mag_i, -- raw data input.//13.09.2011
             carrier_sign => carrier_q_sign, carrier_mag => carrier_q_mag, -- carrier nco inputs.
             mix_sign => mix_q_sign, mix_mag => mix_q_mag); -- outputs
-- carrier nco-------------------------------------------------------
  carrnco: carrier_nco
    port map(clk => clk, rstn => rstn, tic_enable => tic_enable, 
             f_control => carr_nco_fc, 
             carrier_val => carrier_val, 
             i_sign => carrier_i_sign, i_mag => carrier_i_mag, 
             q_sign => carrier_q_sign, q_mag => carrier_q_mag);
-- code nco----------------------------------------------------------
  codenco: code_nco
    port map(clk => clk, rstn => rstn, tic_enable => pre_tic_enable,
             f_control => code_nco_fc,
             hc_enable => hc_enable, code_nco_phase => code_val(9 downto 0));

-- code gen----------------------------------------------------------
  codegen: code_gen
    port map(clk => clk, rstn => rstn, tic_enable => tic_enable,
             hc_enable => hc_enable, prn_key_enable => prn_key_enable,
             prn_key => prn_key, code_slew => code_slew, slew_enable => slew_enable, 
             dump_enable => dump_enable, code_phase => code_val(20 downto 10), 
             early => early_code, prompt => prompt_code, late => late_code);
-- epoch counter------------------------------------------------------
  epc: epoch_counter
    port map(clk => clk, rstn => rstn, 
             tic_enable => tic_enable, dump_enable => dump_enable, 
             epoch_enable => epoch_enable, epoch_load => epoch_load, 
             epoch => epoch, epoch_check => epoch_check);
-- accumulators-------------------------------------------------------
-- in-phase early
  ie: accumulator 
    port map(clk => clk, rstn => rstn, sample_enable => accum_sample_enable, code => early_code, 
             carrier_mix_sign => mix_i_sign, carrier_mix_mag => mix_i_mag, 
             dump_enable => dump_enable, accumulation => i_early);
-- in-phase prompt
  ip: accumulator 
    port map(clk => clk, rstn => rstn, sample_enable => accum_sample_enable, code => prompt_code, 
             carrier_mix_sign => mix_i_sign, carrier_mix_mag => mix_i_mag, 
             dump_enable => dump_enable, accumulation => i_prompt);
-- in-phase late
  il: accumulator 
    port map(clk => clk, rstn => rstn, sample_enable => accum_sample_enable, code => late_code, 
             carrier_mix_sign => mix_i_sign, carrier_mix_mag => mix_i_mag, 
             dump_enable => dump_enable, accumulation => i_late);
-- quadrature-phase early
  qe: accumulator 
    port map(clk => clk, rstn => rstn, sample_enable => accum_sample_enable, code => early_code, 
             carrier_mix_sign => mix_q_sign, carrier_mix_mag => mix_q_mag, 
             dump_enable => dump_enable, accumulation => q_early);
-- quadrature-phase prompt
  qp: accumulator 
    port map(clk => clk, rstn => rstn, sample_enable => accum_sample_enable, code => prompt_code, 
             carrier_mix_sign => mix_q_sign, carrier_mix_mag => mix_q_mag, 
             dump_enable => dump_enable, accumulation => q_prompt);
-- quadrature-phase late
  ql: accumulator 
    port map(clk => clk, rstn => rstn, sample_enable => accum_sample_enable, code => late_code, 
             carrier_mix_sign => mix_q_sign, carrier_mix_mag => mix_q_mag, 
             dump_enable => dump_enable, accumulation => q_late);

  test_point_01 <= hc_enable;
  test_point_02 <= carrier_i_sign;
  test_point_03 <= prompt_code;

end Behavioral;

