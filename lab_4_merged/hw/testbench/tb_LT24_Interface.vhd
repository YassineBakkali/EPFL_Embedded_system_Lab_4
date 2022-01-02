--=============================================================================
--! @file tb_L24_Interface.vhd                                                -
--! @brief Testbench file for LT24_Interface.vhd                              -
--=============================================================================

--! Use standard library
library IEEE;

--! Use logic elements
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--============================================================================
--! Entities                                                                 -
--============================================================================

entity tb_LT24_Interface is
end tb_LT24_Interface;

--============================================================================
--! Architectures                                                            -
--============================================================================

architecture test of tb_LT24_Interface is
   
   --! Constants
   constant CLK_PERIOD : time := 20 ns;
   constant NUM_CYCLES_PER_TRANSFER : integer := 6;
   
   --! LT24_Interface ports
   
   --! clock, resets 
   signal clk              :       std_logic;
   signal nReset           :       std_logic;
   signal LT24_Res_n       :       std_logic;
   
   --! 01 write command
   --! 10 write data
   --! 00 no operation
   signal cmd_or_data      :       std_logic_vector(1 downto 0);
   
   --! contains the command/data to write
   --! to start displaying data, cmd_data = '2C'
   signal cmd_data         :       std_logic_vector(15 downto 0);
   
   --! command to turn ON or OFF the LCD
   signal cmd_LCD_ON       :       std_logic;
   
   --! LT24 signals
   signal LT24_CSX         :       std_logic;
   signal LT24_DCX         :       std_logic;
   signal LT24_D           :       std_logic_vector(15 downto 0);
   signal LT24_RDX         :       std_logic;
   signal LT24_WRX         :       std_logic;
   signal LT24_LCD_ON      :       std_logic;
   
   --! FIFO signals
   signal FIFO_empty       :       std_logic;
   signal FIFO_q           :       std_logic_vector(15 downto 0);
   signal FIFO_rdreq       :       std_logic;
   
   --! Requests the master to begin the data transfer
   signal start_out        :       std_logic;
   
   --! Indicates when display is finished
   signal display_finished :       std_logic;
      
   --! Indicates start of transfer
   signal transfer_start   :       std_logic;
   
      --! '1' if writing cmd/data or displaying is completed
   signal cmd_data_ready   :       std_logic;
   

   
   begin
      -- Instantiate DUT
      dut : entity work.LT24_Interface
      
      port map (
         clk              => clk,
         nReset           => nReset,
         LT24_Res_n       => LT24_Res_n,
         cmd_or_data      => cmd_or_data,
         cmd_data         => cmd_data,
         cmd_LCD_ON       => cmd_LCD_ON,
         LT24_CSX         => LT24_CSX,
         LT24_DCX         => LT24_DCX,
         LT24_D           => LT24_D,
         LT24_RDX         => LT24_RDX,
         LT24_WRX         => LT24_WRX,
         LT24_LCD_ON      => LT24_LCD_ON,
         FIFO_empty       => FIFO_empty,
         FIFO_q           => FIFO_q,
         FIFO_rdreq       => FIFO_rdreq,
         start_out        => start_out,
         display_finished => display_finished,
         transfer_start   => transfer_start,
         cmd_data_ready   => cmd_data_ready
      );
      
   --! Clock generation ------------------------------------------------------
   
   clk_generation : process
   begin
     clk <= '1';
     wait for CLK_PERIOD / 2;
     clk <= '0';
     wait for CLK_PERIOD / 2;
   end process clk_generation;   
   
   
   --! Simulation ============================================================
   
   
   simulation : process
   
   begin
   
--      -- Reset
--      nReset <= '0';
--      wait for CLK_PERIOD;
--      nReset <= '1';
      FIFO_empty <= '0';
		transfer_start <= '0';
      -- Turn ON LCD
      cmd_LCD_ON <= '1';
      
      -- Send a command
      cmd_data <= x"0001"; 
      cmd_or_data <= "01";
      
      
      wait for 5*CLK_PERIOD;
      cmd_or_data <= "00";
      
      wait for CLK_PERIOD;
      
      -- Send data from Avalon slave register
      cmd_data <= x"0002"; 
      cmd_or_data <= "10";
      
      wait for 4*CLK_PERIOD;
      cmd_or_data <= "00";
      
      wait for CLK_PERIOD;
      
      -- Send data from FIFO
      -- This test sends the same data repeatedly until all pixels are sent
      -- (320 x 240 x 6 = 9216000 cycles to send 1 frame if the FIFO is never empty)
      cmd_data <= x"002c";
      cmd_or_data <= "01";
      
      FIFO_q <= x"1234";
		
      wait for 5*CLK_PERIOD;
      transfer_start <= '1';
      cmd_data <= x"0000"; 
      cmd_or_data <= "00";
--    
    wait for 4*CLK_PERIOD;
    
      FIFO_empty <= '0';
      
      wait for 4*CLK_PERIOD;
      
      -- Wait for 5 transfers
      wait for 5*NUM_CYCLES_PER_TRANSFER*CLK_PERIOD;
		wait for 4*CLK_PERIOD;
      FIFO_empty <= '1';
--      FIFO_q <= x"0000";

      -- Wait a few transfers. It should stop sending data to the LT24 as long as 
      -- the FIFO is empty.
      wait for 3*NUM_CYCLES_PER_TRANSFER*CLK_PERIOD;
      
      FIFO_empty <= '0';
--      FIFO_q <= x"1234";

    wait for 5*CLK_PERIOD;
      
--		--! Turn off LCD

      
      wait for 500000*CLK_PERIOD;
      cmd_LCD_ON <= '0';  
   
   end process simulation;
   
end architecture test;