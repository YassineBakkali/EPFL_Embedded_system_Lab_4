--===========================================================================--
--! @file tb_slave_interface.vhd                                             --
--! @brief Testbench file for slave_interface.vhd                            --
--===========================================================================--

--! Use standard library
library IEEE;

--! Use logic elements
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--==========================================================================--
--! Entities                                                                --
--==========================================================================--

entity tb_slave_interface is
end tb_slave_interface;

--==========================================================================--
--! Architectures                                                           --
--==========================================================================--

--! @brief      Architecture definition of tb_slave_interface
--! @details    Simulates a 50 MHz clock input, the ready signal 
--!             of the LT24 and the outputs sent to configure both
--!             the DMA and the LCD display.
architecture test of tb_slave_interface is
    
    constant CLK_PERIOD      : time := 20 ns                    ;  --! Period in nanoseconds of clk_in

    signal clk               : std_logic                        ;  --! 50 MHz clock input
    signal nReset            : std_logic                        ;  --! Active low reset input
            
    signal as_writedata      : std_logic_vector(31 downto 0)    ;  --! Avalon slave write data input
    signal as_write          : std_logic                        ;  --! Avalon slave write input             
    signal as_address        : std_logic_vector(2 downto 0)     ;  --! Avalon slave address input             
    signal as_read           : std_logic                        ;  --! Avalon slave read input             
    signal as_readdata       : std_logic_vector(31 downto 0)    ;  --! Avalon slave read data output 

    signal cmd_or_data       : std_logic_vector(1 downto 0)     ;  --! Command/Data type output
    signal cmd_data          : std_logic_vector(15 downto 0)    ;  --! Command/Data output
    signal cmd_data_ready    : std_logic                        ;  --! Indicates when a command/data was transmitter
    signal lcd_on_out        : std_logic                        ;  --! Indicates if the LCD should be ON or OFF

    signal start_address_out : std_logic_vector(31 downto 0)    ;  --! First pixel memory address output
    signal burst_tot_out     : std_logic_vector(7 downto 0)     ;  --! Length of a burst transfer output
    
    signal iRegCmdData       : std_logic_vector(15 downto 0)    ;  --! cmd_data register

begin

-- Instantiate DUT
   dut : entity work.Slave_Interface
    
   port map (
      clk               => clk,
      as_writedata      => as_writedata,
      as_write          => as_write,
      as_address        => as_address,
      as_read           => as_read,
      as_readdata       => as_readdata,
      cmd_or_data       => cmd_or_data,
      cmd_data          => cmd_data,
      cmd_data_ready    => cmd_data_ready,
      lcd_on_out        => lcd_on_out,
      start_address_out => start_address_out,
      burst_tot_out     => burst_tot_out,     
      nReset            => nReset
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
   
      -- Reset
      
      nReset <= '0';
      wait for CLK_PERIOD;
      nReset <= '1';  
     
     
      -- Turn LCD ON
      
      as_write <= '1';
      as_read <= '0';
		cmd_data_ready <= '0';
      
      as_address <= "100";
      
      wait for CLK_PERIOD;
      
      as_writedata <= 32b"1";
      
      wait for CLK_PERIOD;
      
      as_write <= '0';
      
      wait for CLK_PERIOD;
     
      -- cmd_or_data register writing
     
      cmd_data_ready <= '0';
      
      as_write <= '1';
     
      wait for CLK_PERIOD;
     
      as_address <= "001";
      as_writedata <= 32b"010";
      
      wait for CLK_PERIOD;
      -- cmd_data register writing
     
      as_address <= "010";
      as_write <= '1';
      
      wait for CLK_PERIOD;
      
      as_writedata <= 32x"2C";
      
      wait for CLK_PERIOD;
      
      as_write <= '0';
		
		wait for CLK_PERIOD*4;

      cmd_data_ready <= '1';
		
		wait for CLK_PERIOD;
		
		cmd_data_ready <='0';
		
		wait for CLK_PERIOD;
     
      wait for 10*CLK_PERIOD;
     
      -- Command sent to LT24 

      cmd_data_ready <= '1';
     
      wait for CLK_PERIOD;
     
      cmd_data_ready <= '0';
      
      wait for CLK_PERIOD;
      
      -- Read RegCmdData register
      
      as_write <= '0';
      as_read <= '1';
      
      as_address <= "010";
      
      wait for CLK_PERIOD;
      
      iRegCmdData <= as_readdata(15 downto 0);
      
      wait for 10*CLK_PERIOD;
        
   end process simulation;
   
end architecture test;

