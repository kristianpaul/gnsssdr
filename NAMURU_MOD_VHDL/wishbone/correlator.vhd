----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 		Gavrilov A.
--           
-- 
-- Create Date:   09.12.2011
-- Design Name: 
-- Module Name:    
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
Library UNISIM;
use UNISIM.vcomponents.all;

entity gps_baseband is
    Port ( sys_clk :      in    STD_LOGIC; --16MHz input clock from gnss front-end.
           sys_rst :      in    STD_LOGIC;
			  
           sign_i :       in    STD_LOGIC; -- raw data in from RF front end. I-channel.
           sign_q :       in    STD_LOGIC; -- raw data in from RF front end. Q-channel.
			  
           wb_adr_i :     in    STD_LOGIC_VECTOR(31 downto 0);
           wb_dat_o :     out   STD_LOGIC_VECTOR(31 downto 0);
           wb_dat_i :     in    STD_LOGIC_VECTOR(31 downto 0);
           wb_sel_i :     in    STD_LOGIC_VECTOR(3 downto 0);
           wb_stb_i :     in    STD_LOGIC;
           wb_cyc_i :     in    STD_LOGIC;
           wb_ack_o :     out   STD_LOGIC;
           wb_we_i :      in    STD_LOGIC;
			  
--           csn :          in    STD_LOGIC;
--           wen :          in    STD_LOGIC;
--           oen :          in    STD_LOGIC;
--           address :      in    STD_LOGIC_VECTOR (9 downto 0); --corrletor adress lines.
--           dio :          inout STD_LOGIC_VECTOR(15 downto 0); -- data lines.
			  
           accum_int :    out   STD_LOGIC; -- interrupt pulse to tell FW to collect accumulation data, cleared on STATUS read.
			  
			  test_point_01: out   STD_LOGIC;
           test_point_02: out   STD_LOGIC;
           test_point_03: out   STD_LOGIC;
           test_point_04: out   STD_LOGIC;
           test_point_05: out   STD_LOGIC);
end gps_baseband; 

architecture Behavioral of gps_baseband is
  --signals used to convert data from wishbone bus to local core signals:
  signal address: STD_LOGIC_VECTOR(7 downto 0);

  signal rstn:   STD_LOGIC;        -- Global reset in the design.
  signal sw_rst: STD_LOGIC := '0'; -- Software reset.
  
  --signals for my hardware features:
  signal mag_i: STD_LOGIC := '0';
  signal mag_q: STD_LOGIC := '0';
  signal read_data_reg:   STD_LOGIC_VECTOR(15 downto 0); --This signal for memory data lines!
  
  --signals for debugging memory-interface:
  type reg_file_type is array (7 downto 0) of STD_LOGIC_VECTOR (31 downto 0) ; --128 регистров для тестирования памяти.
  signal test_reg : reg_file_type;
  
  -- control registers:
  signal prog_tic:       STD_LOGIC_VECTOR (23 downto 0); --TIC_divide value;
  signal prog_accum_int: STD_LOGIC_VECTOR (23 downto 0); --ACCUM_INT_divide value;
  
  -- status registers:
  signal status:       STD_LOGIC_VECTOR (1 downto 0); -- TIC = bit 0, ACCUM_INT = bit 1.
  signal status_clean: STD_LOGIC; --New signal for namuru design. 
                                  --Now status isn't automatically cleaned after read. 
                                  --Special command must ne sent to clean status. This command sets "status_clean" to '1'.
  signal new_data: STD_LOGIC_VECTOR (0 downto 0); -- chan0 = bit 0, chan1 = bit 1 etc.
  signal new_data_clean: STD_LOGIC; --New signal for namuru design. 
                                    --Now status isn't automatically cleaned after read. 
                                    --Special command must ne sent to clean status. This command sets "status_clean" to '1'.
  
  -- time-base signals:
  signal pre_tic_enable, tic_enable, accum_sample_enable, accum_enable_s: STD_LOGIC;
  signal tic_count:   STD_LOGIC_VECTOR (23 downto 0);
  signal accum_count: STD_LOGIC_VECTOR (23 downto 0);
  
  --channel 0 registers:
  signal ch0_prn_key: STD_LOGIC_VECTOR (9 downto 0);
  signal ch0_carr_nco: STD_LOGIC_VECTOR (28 downto 0);
  signal ch0_code_nco: STD_LOGIC_VECTOR (27 downto 0);
  signal ch0_code_slew: STD_LOGIC_VECTOR (10 downto 0);
  signal ch0_epoch_load: STD_LOGIC_VECTOR (10 downto 0);
  signal ch0_prn_key_enable, ch0_slew_enable, ch0_epoch_enable: STD_LOGIC;
  signal ch0_dump: STD_LOGIC;
  signal ch0_i_early, ch0_q_early, ch0_i_prompt, ch0_q_prompt, ch0_i_late, ch0_q_late: STD_LOGIC_VECTOR (15 downto 0);
  signal ch0_carrier_val: STD_LOGIC_VECTOR (31 downto 0);
  signal ch0_code_val: STD_LOGIC_VECTOR (20 downto 0);
  signal ch0_epoch, ch0_epoch_check: STD_LOGIC_VECTOR (10 downto 0);
  
  signal ch0_test_point_01: STD_LOGIC;
  signal ch0_test_point_02: STD_LOGIC;
  signal ch0_test_point_03: STD_LOGIC;
  
--------------------END_LOCAL_SIGNAL_DECLARATION_SECTION----------------------------------------------
  	
  component time_base
    port ( clk :                 in   STD_LOGIC;
           rstn :                in   STD_LOGIC;
           tic_divide :          in   STD_LOGIC_VECTOR (23 downto 0);
           accum_divide :        in   STD_LOGIC_VECTOR (23 downto 0);
           pre_tic_enable :      out  STD_LOGIC;
           tic_enable :          out  STD_LOGIC;
           accum_enable :        out  STD_LOGIC;
           accum_sample_enable : out  STD_LOGIC;
           tic_count :           out  STD_LOGIC_VECTOR (23 downto 0);
           accum_count :         out  STD_LOGIC_VECTOR (23 downto 0));
  end component;

  component tracking_channel
    port ( clk :                 in  STD_LOGIC;
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
  end component;
	
  
begin
  --wb_ack_o <= wb_stb_i;
  process(sys_clk)
  begin
    if (sys_clk'event and sys_clk='1') then
      if (sys_rst='1') then
        wb_ack_o <= '0';
      else
        if ( (wb_cyc_i='1') and (wb_stb_i='1') ) then
          wb_ack_o <= '1';
        else
          wb_ack_o <= '0';
        end if;
      end if;
    end if;
  end process;

  rstn <= (not sw_rst); -- Only sorfware reset for now... Hardware reset should also be added.

-- time base------------------------------------------------------------------------------------------
  tb: time_base
    port map(clk => sys_clk, rstn => rstn, 
	          tic_divide => prog_tic, accum_divide => prog_accum_int,
				 pre_tic_enable => pre_tic_enable, tic_enable => tic_enable,
				 accum_enable => accum_enable_s, accum_sample_enable => accum_sample_enable, 
				 tic_count => tic_count, accum_count => accum_count);

---- connect up tracking channels---------------------------------------------------------------------
  tc0: tracking_channel
    port map(clk => sys_clk, rstn => rstn, 
             accum_sample_enable => accum_sample_enable,
             if_sign_i => sign_i, if_mag_i => mag_i, 
             if_sign_q => sign_q, if_mag_q => mag_q, 
             pre_tic_enable => pre_tic_enable,
             tic_enable => tic_enable,
             carr_nco_fc => ch0_carr_nco, --chnXX
             code_nco_fc => ch0_code_nco, --chnXX
             prn_key => ch0_prn_key, --chnXX
             prn_key_enable => ch0_prn_key_enable, --chnXX
             code_slew => ch0_code_slew, --chnXX
             slew_enable => ch0_slew_enable, --chnXX
             epoch_enable => ch0_epoch_enable, --chnXX
             dump => ch0_dump, --chnXX
             i_early => ch0_i_early, --chnXX
             q_early => ch0_q_early, --chnXX
             i_prompt => ch0_i_prompt, --chnXX
             q_prompt => ch0_q_prompt, --chnXX
             i_late => ch0_i_late, --chnXX
				 q_late => ch0_q_late,
             carrier_val => ch0_carrier_val, --chnXX
             code_val => ch0_code_val, --chnXX
             epoch_load => ch0_epoch_load,
             epoch => ch0_epoch, --chnXX
             epoch_check => ch0_epoch_check,
             test_point_01 => ch0_test_point_01,
             test_point_02 => ch0_test_point_02,
             test_point_03 => ch0_test_point_03); --chnXX
				 

--address decoder-------------------------------------------------------------------------------------
  address <= wb_adr_i(9 downto 2);
  
--test_memory_space-code_for_testing_only!--------------------------

--  process(sys_clk)
--  begin
--    if (sys_clk'event and sys_clk='0') then --sys_clk='0' - otherwise it doesn't work! Testbench must be prepared!
--		if (rstn = '0') then
--        sw_rst <= '0';
--      else
--
--        case to_integer(unsigned(address)) is
--
--          when 0 to 255 =>
--				wb_dat_o <= "000000000000000000000000" & address;
--				
--          when others =>
--            wb_dat_o <= (others=>'0');
--          
--        end case;
--		  
--      end if;
--    end if;
--  end process;
  
----------------------------------------------
  
  process(sys_clk)
  begin
    if (sys_clk'event and sys_clk='0') then--Pay attention to 'sys_clk='0'' - must understand!
      ---if (sys_rst = '0') then --pay attention! Should be checked and used in future!!!
		if (rstn = '0') then --pay attention! Should be checked and used in future!!!
        sw_rst <= '0';
        ch0_carr_nco <= (others=>'0');
        ch0_code_nco <= (others=>'0');
      else

        sw_rst             <= '0';
        status_clean       <= '0';
		  ch0_prn_key_enable <= '0';
		  ch0_slew_enable    <= '0';
        
        --case to_integer(unsigned(address)) is
        case to_integer(unsigned(address)) is

----------channel 0:----------------------------------------------------------------------------------
          when 0 =>
            ch0_prn_key_enable <= ( wb_stb_i and wb_we_i );
				if ( (wb_cyc_i and wb_stb_i and wb_we_i) = '1' ) then
              ch0_prn_key <= wb_dat_i(9 downto 0);
            end if;
          
          when 1 =>
            if ( (wb_cyc_i and wb_stb_i and wb_we_i) = '1' ) then
              ch0_carr_nco <= wb_dat_i(28 downto 0);
            end if;
          
          when 2 => 
            if ( (wb_cyc_i and wb_stb_i and wb_we_i) = '1' ) then
              ch0_code_nco <= wb_dat_i(27 downto 0);
            end if;
          
          when 3 => 
            ch0_slew_enable <= ( wb_stb_i and wb_we_i );
            if ( (wb_cyc_i and wb_stb_i and wb_we_i) = '1' ) then
              ch0_code_slew <= wb_dat_i(10 downto 0);
            end if;
          
          when 4 =>
            wb_dat_o <= "0000000000000000" & ch0_i_early;
          
          when 5 =>
            wb_dat_o <= "0000000000000000" & ch0_q_early;
          
          when 6 =>
            wb_dat_o <= "0000000000000000" & ch0_i_prompt;
          
          when 7 =>
            wb_dat_o <= "0000000000000000" & ch0_q_prompt;
          
          when 8 =>
            wb_dat_o <= "0000000000000000" & ch0_i_late;
          
          when 9 =>
            wb_dat_o <= "0000000000000000" & ch0_q_late;
          
----------control section:----------------------------------------------------------------------------
          when 240 =>
            sw_rst <= (wb_cyc_i and wb_stb_i and wb_we_i); --software reset;
          
          when 241 => 
            if ( (wb_cyc_i and wb_stb_i and wb_we_i) = '1' ) then
              prog_tic <= wb_dat_i(23 downto 0); --program TIC;
            end if;
          
          when 242 =>
            if ( (wb_cyc_i and wb_stb_i and wb_we_i) = '1' ) then
              prog_accum_int <= wb_dat_i(23 downto 0); --program ACCUM_INT;
            end if;
          
----------status section:-----------------------------------------------------------------------------
          when 224 => --get status and pulse status_flag to clear status.
            wb_dat_o <= "000000000000000000000000000000" & status; --only 2 status bits, therefore need to pad 30 bits;

          when 225 =>
            status_clean <= (wb_cyc_i and wb_stb_i and wb_we_i); --clear status register;

          when 226 => --get new data;
            wb_dat_o <= "0000000000000000000000000000000" & new_data(0); -- one new_data_ bit per channel, need to pad other bits;

          when 227 =>
            new_data_clean <= (wb_cyc_i and wb_stb_i and wb_we_i); --clear status register;
				
----------test_memory_registers:----------------------------------------------------------------------
			 when 32 to 39 => --32 регистров для тестирования памяти.
            if ( (wb_cyc_i and wb_stb_i and wb_we_i) = '1' ) then
              test_reg(to_integer(unsigned(address)) - 32) <= wb_dat_i;
            end if; 

--------------read from memory:-----------------------------------------------------------------------
          
          when 64 to 71 => --7 регистров для тестирования памяти.
            wb_dat_o <= test_reg(to_integer(unsigned(address)));
			           
------------------------------------------------------------------------------------------------------
			 
          when others =>
            wb_dat_o <= (others=>'0');
          
        end case;
      end if;
    end if;
  end process;
  
----Interrupt generation for external MCU:------------------------------------------------------------
  --process to reset the status register after a read.
  --also create accum_int signal that is cleared after status read.
  process(sys_clk)
  begin
    if(sys_clk'event and sys_clk='1') then
      --if ( (rstn='0') or (status_read='1') ) then
      if (rstn='0') then
        status <= "00";
        accum_int <= '0';
      else
        if (status_clean='1') then --New signal for namuru! Used to clean interrupt and status (no autocleaning).
          status <= "00";
          accum_int <= '0';
        end if;
        if (tic_enable='1') then
          status(0) <= '1';
        end if;
        if (accum_enable_s='1') then
          status(1) <= '1';
          accum_int <= '1';
        end if;
      end if;
    end if;
  end process;  
  
----new_data_signal_generation_(simplified_version!!!)------------------------------------------------
  process(sys_clk)
  begin
    if (sys_clk'event and sys_clk='1') then
      if (rstn='0') then
        new_data <= (others=>'0');
      else
        if (new_data_clean='1') then
          new_data <= (others=>'0');
        end if;
        if (ch0_dump='1') then
          new_data(0) <= '1';
        end if;
      end if;
    end if;
  end process; 
  
--------------------Test_points_for_debugging---------------------------------------------------------  
  
  --test_point_01 <= accum_sample_enable;
  ---test_point_02 <= ch0_dump;
  test_point_03 <= pre_tic_enable;
  
  --test_point_02 <= ;
  --test_point_03 <= (new_data_read_started xor new_data_read_started);
  --test_point_04 <= tic_enable;
  test_point_05 <= accum_enable_s;
  --test_point_04 <= oen;
  --test_point_05 <= csn;
  
  --test_point_03 <= ch0_test_point_01;
  --test_point_04 <= ch0_test_point_02;
  --test_point_05 <= ch0_test_point_03;
  ---test_point_05 <= ch0_test_point_01;
  ---test_point_05 <= ch0_test_point_02;
  ---test_point_05 <= ch0_test_point_03;
  ---test_point_05 <= accum_enable_s;
  
end Behavioral;

