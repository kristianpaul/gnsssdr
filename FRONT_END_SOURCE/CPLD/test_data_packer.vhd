--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:16:37 04/27/2010
-- Design Name:   
-- Module Name:   C:/GavAI/GPS_rcv_final/CPLD_data_packer/test_data_packer.vhd
-- Project Name:  CPLD_data_packer
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: data_packer
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
 
ENTITY test_data_packer IS
END test_data_packer;
 
ARCHITECTURE behavior OF test_data_packer IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT data_packer
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         di : IN  std_logic_vector(3 downto 0);
         do : OUT  std_logic_vector(15 downto 0);
         SLWR : OUT  std_logic;
         FLAGA : IN  std_logic;
         FLAGB : IN  std_logic;
         FLAGC : IN  std_logic;
         IFCLK : IN  std_logic;
         CLK0 : IN  std_logic;
         SLRD : OUT  std_logic;
         AntFlag_in : IN  std_logic;
         LD_in : IN  std_logic;
         AntFlag_out : OUT  std_logic;
         LD_out : OUT  std_logic;
         ref_clk_sel : IN  std_logic;
         ext_freq_dsbl : OUT  std_logic;
         TCXO_dsbl : OUT  std_logic;
         err_out : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal di : std_logic_vector(3 downto 0) := (others => '0');
   signal FLAGA : std_logic := '0';
   signal FLAGB : std_logic := '0';
   signal FLAGC : std_logic := '0';
   signal IFCLK : std_logic := '0';
   signal CLK0 : std_logic := '0';
   signal AntFlag_in : std_logic := '0';
   signal LD_in : std_logic := '0';
   signal ref_clk_sel : std_logic := '0';

 	--Outputs
   signal do : std_logic_vector(15 downto 0);
   signal SLWR : std_logic;
   signal SLRD : std_logic;
   signal AntFlag_out : std_logic;
   signal LD_out : std_logic;
   signal ext_freq_dsbl : std_logic;
   signal TCXO_dsbl : std_logic;
   signal err_out : std_logic;

   -- Clock period definitions
   constant clk_period : time := 50 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: data_packer PORT MAP (
          clk => clk,
          rst => rst,
          di => di,
          do => do,
          SLWR => SLWR,
          FLAGA => FLAGA,
          FLAGB => FLAGB,
          FLAGC => FLAGC,
          IFCLK => IFCLK,
          CLK0 => CLK0,
          SLRD => SLRD,
          AntFlag_in => AntFlag_in,
          LD_in => LD_in,
          AntFlag_out => AntFlag_out,
          LD_out => LD_out,
          ref_clk_sel => ref_clk_sel,
          ext_freq_dsbl => ext_freq_dsbl,
          TCXO_dsbl => TCXO_dsbl,
          err_out => err_out
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100ms.
      wait for clk_period*10;

      -- insert stimulus here 
      di <= x"1"; wait for 50 ns;
      di <= x"2"; wait for 50 ns;
      di <= x"2"; wait for 50 ns;
      di <= x"2"; wait for 50 ns;
      di <= x"3"; wait for 50 ns;
      di <= x"3"; wait for 50 ns;
      di <= x"3"; wait for 50 ns;
      di <= x"0"; wait for 50 ns;
      di <= x"1"; wait for 50 ns;
      di <= x"1"; wait for 50 ns;
      di <= x"1"; wait for 50 ns;
      di <= x"2"; wait for 50 ns;
      di <= x"3"; wait for 50 ns;
      di <= x"0"; wait for 50 ns;
      di <= x"0"; wait for 50 ns;
      di <= x"0"; wait for 50 ns;

      wait;
   end process;

END;
