--=============================================================================
--! @file Slave_Interface.vhd                                                --
--! @brief outputs a pwm signal with configurable period, duty cycle         --
--!        and polarity                                                      --
--=============================================================================

--! Use standard library
library IEEE;

--! Use logic elements
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


--============================================================================
--! Entities                                                                --
--============================================================================

--! slave interface entity
entity Slave_Interface is
   port (
   
         clk                 : in  std_logic;                        --! 50 MHz clock input
         nReset              : in  std_logic;                        --! Active low reset input
         
         as_writedata        : in  std_logic_vector(31 downto 0);    --! Avalon slave write data input
         as_write            : in  std_logic;                        --! Avalon slave write input             
         as_address          : in  std_logic_vector(2 downto 0);     --! Avalon slave address input             
         as_read             : in  std_logic;                        --! Avalon slave read input             
         as_readdata         : out std_logic_vector(31 downto 0);    --! Avalon slave read data output 

         cmd_or_data         : out std_logic_vector(1 downto 0);     --! Command/Data type output
         cmd_data            : out std_logic_vector(15 downto 0);    --! Command/Data output
         cmd_data_ready      : in  std_logic;                        --! Indicates when command or data is completed
         lcd_on_out          : out std_logic;                        --! LCD ON signal

         start_address_out   : out std_logic_vector(31 downto 0);    --! First pixel memory address output
         burst_tot_out       : out std_logic_vector(7 downto 0)      --! Length of a burst transfer output  
   ); 
            
end entity Slave_Interface;

--============================================================================
--! Architectures                                                           --
--============================================================================

--! @brief      Architecture definition of the slave_interface
--! @details    Contains the main configuration registers of 
--!             the LCD controller. They can be written on or read.
--!             Their contents are sent to the Master DMA and LT24 interface
--!             in order to configure and initiate the data transfer.
architecture comp of Slave_Interface is

   --! Internal signals ------------------------------------------------------
   
   signal RegStartAddress   : std_logic_vector(31 downto 0);
   signal RegCmdOrData      : std_logic_vector(1 downto 0);
   signal RegCmdData        : std_logic_vector(15 downto 0);
   signal RegCmdDataReady   : std_logic;
   signal RegBurstTot       : std_logic_vector(7 downto 0);
   signal RegLCDON          : std_logic;
   
begin

   -- Send signals to corresponding ports

   send_signals: process(clk, nReset) is
   
   begin
      if nReset = '0' then
         start_address_out    <= (others =>'0');
         burst_tot_out        <= (others =>'0');
         cmd_or_data          <= (others =>'0');
         cmd_data             <= (others =>'0');
         lcd_on_out               <= '0';
         
      elsif rising_edge(clk) then
         start_address_out <= RegStartAddress;
         burst_tot_out <= RegBurstTot;
         lcd_on_out <= RegLCDON;
         cmd_or_data <= RegCmdOrData;
         cmd_data <= RegCmdData;
         
         if RegLCDON = '0' then
            cmd_or_data    <= (others => '0');
            cmd_data       <= (others => '0');           
         end if;
         
      end if;
      
   end process send_signals;

   -- Avalon slave write to registers -----------------------------------------

   slave_write: process(clk, nReset) is
   
      begin
      
         if nReset = '0' then
            RegStartAddress    <= (others =>'0');
            RegCmdOrData       <= (others =>'0');
            RegCmdData         <= (others =>'0');
            RegCmdDataReady    <= '0';
            RegBurstTot        <= (others =>'0');
            RegLCDON           <= '0';
            
         elsif rising_edge(clk) then     
         
            if as_write = '1' then
               case as_address is
                  when "000"     => RegStartAddress   <= as_writedata;          
                  when "001"     => RegCmdOrData      <= as_writedata(1 downto 0);
                  when "010"     => RegCmdData        <= as_writedata(15 downto 0);
                  when "011"     => RegBurstTot       <= as_writedata(7 downto 0);
                  when "100"     => RegLCDON          <= as_writedata(0);
                  when others    => null;
               end case;
            end if;
            
            if cmd_data_ready = '1' then
               RegCmdData         <= (others =>'0');
               RegCmdOrData       <= (others =>'0');
            end if;
            
         end if;
         
      end process;

   -- Avalon slave read from registers ----------------------------------------

   slave_read: process(clk) is
   begin
        if rising_edge(clk) then
            as_readdata <= (others => '0');
            if as_read = '1' then
                case as_address is
                    when "000"   => as_readdata                <= RegStartAddress;
                    when "001"   => as_readdata(1 downto 0)    <= RegCmdOrData;
                    when "010"   => as_readdata(15 downto 0)   <= RegCmdData;
                    when "011"   => as_readdata(7 downto 0)    <= RegBurstTot;
                    when "100"   => as_readdata(0)             <= RegLCDON;
                    when others  => null;
                end case;
            end if;
        end if;
        
   end process;
   
end architecture comp;  
   
      	