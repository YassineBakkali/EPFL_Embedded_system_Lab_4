--===========================================================================--
--! @file tb_master_interface.vhd                                            --
--! @brief Testbench file for master_interface.vhd                           --
--===========================================================================--

--! Use standard library
library IEEE;

--! Use logic elements
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--==========================================================================--
--! Entities                                                                --
--==========================================================================--

entity tb_master_interface_DMA is
end tb_master_interface_DMA;

--==========================================================================--
--! Architectures                                                           --
--==========================================================================--

--! @brief      Architecture definition of tb_master_interface
--! @details    Simulates a 50 MHz clock input and tests the behaviour of 
--!             the master during a transfer of 76800 pixels and 
--!             whenever the FIFO is full.

architecture test of tb_master_interface_DMA is
   
         constant CLK_PERIOD     : time := 20 ns                  ;  --! Period in nanoseconds of clk

         signal clk              : std_logic                      ;  --! 50 MHz clock input
         signal nReset           : std_logic                      ;  --! Active low reset input
         
         signal am_waitrequest   : std_logic                      ;  --! Avalon master wait request input              
         signal am_address       : std_logic_vector(31 downto 0)  ;  --! Avalon master address output             
         signal am_read          : std_logic                      ;  --! Avalon master read output             
         signal am_readdata      : std_logic_vector(31 downto 0)  ;  --! Avalon master read data input
         signal am_readdatavalid : std_logic                      ;  --! Avalon master read data valid input
         signal am_burstcount    : std_logic_vector(7 downto 0)   ;  --! Avalon master burst count output
         signal am_byteenable    : std_logic_vector(3 downto 0)   ;  --! Avalon master byte enable output
			
			signal FIFO_aclr        : std_logic                      ;  --! FIFO clear
         signal FIFO_almost_full : std_logic                      ;  --! FIFO almost full input
         signal FIFO_data        : std_logic_vector(15 downto 0)  ;  --! FIFO data output
         signal FIFO_wrreq       : std_logic                      ;  --! FIFO write request output
         
         signal start_in         : std_logic                      ;  --! Data transfer start signal input
         signal start_address_in : std_logic_vector(31 downto 0)  ;  --! First pixel memory address input
         signal burst_tot_in     : std_logic_vector(7 downto 0)   ;  --! Length of a burst transfer input
         signal display_finished : std_logic                      ;  --! Indicates when display is finished
         signal transfer_start   : std_logic                      ;  --! Indicates start of transfer         
         begin
-- Instantiate DUT
   dut : entity work.Master_Interface_DMA
      port map(
			clk => clk,
         nReset => nReset,
         am_waitrequest => am_waitrequest,
         am_address => am_address,
         am_read => am_read,
         am_readdata => am_readdata,
         am_readdatavalid => am_readdatavalid,
         am_burstcount => am_burstcount,
         am_byteenable => am_byteenable,
         FIFO_aclr => FIFO_aclr,
         FIFO_almost_full => FIFO_almost_full,
         FIFO_data => FIFO_data, 
			FIFO_wrreq => FIFO_wrreq,
         start_in => start_in,
         start_address_in => start_address_in,
         burst_tot_in => burst_tot_in,
			display_finished => display_finished,
			transfer_start => transfer_start
			);
                
    clk_generation : process
    begin
        clk <= '1';
        wait for CLK_PERIOD / 2;
        clk <= '0';
        wait for CLK_PERIOD / 2;
    end process clk_generation;
    
    simulation : process
    begin
    
       -- Reset
       
       nReset <= '0';
       wait for CLK_PERIOD;
       nReset <= '1';
       wait for CLK_PERIOD;
       
       -- Initialization
       
		 display_finished <= '0';
       am_waitrequest <= '0';
		 start_address_in <= (others => '0');
		 start_in <= '0';
       am_readdatavalid <= '1';
       am_readdata <= x"0000FFFF";
       FIFO_almost_full <= '0';
       
       start_address_in <= x"0000014B";
       burst_tot_in <= x"08"; 
       
       wait for CLK_PERIOD;    
       
       -- Data transfer starts
       
       start_in <= '1' ;
       
       wait for CLK_PERIOD*2;
       
       start_in <= '0';
       
       wait for CLK_PERIOD*60000;
       
       -- Transfer interrupts
       
       FIFO_almost_full <= '1';
       
       wait for CLK_PERIOD*15;
       
       -- Transfer resumes
       
       FIFO_almost_full <= '0';
       
       wait for CLK_PERIOD*55615;
		 
		 display_finished <= '1';
    
		 wait for CLK_PERIOD;
		
		 display_finished <= '0';
		 
		 wait for CLK_PERIOD*10;
		 
    end process simulation;
    
end architecture test;
