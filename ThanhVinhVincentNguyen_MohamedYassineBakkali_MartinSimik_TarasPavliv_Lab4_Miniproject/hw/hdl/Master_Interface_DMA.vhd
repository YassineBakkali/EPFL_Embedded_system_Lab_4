--=============================================================================
--! @file Master_Interface_DMA.vhd                                           --
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
   
--! master DMA interface entity
entity Master_Interface_DMA is
   port (
   
         clk               : in  std_logic;                       --! 50 MHz clock input
         nReset            : in  std_logic;                       --! Active low reset input
                   
         am_waitrequest    : in  std_logic;                       --! Avalon master wait request input             
         am_address        : out std_logic_vector(31 downto 0);   --! Avalon master address output             
         am_read           : out std_logic;                       --! Avalon master read output             
         am_readdata       : in  std_logic_vector(31 downto 0);   --! Avalon master read data input
         am_readdatavalid  : in  std_logic;                       --! Avalon master read data valid input
         am_burstcount     : out std_logic_vector(7 downto 0);    --! Avalon master burst count output
         am_byteenable     : out std_logic_vector(3 downto 0);    --! Avalon master byte enable output
         
         FIFO_aclr         : out std_logic;                       --! FIFO clear
         FIFO_almost_full  : in  std_logic;                       --! FIFO almost full input
         FIFO_data         : out std_logic_vector(15 downto 0);   --! FIFO data output
         FIFO_wrreq        : out std_logic;                       --! FIFO write request output
         
         start_in          : in  std_logic;                       --! Data transfer start signal input
         start_address_in  : in  std_logic_vector(31 downto 0);   --! First pixel memory address input
         burst_tot_in      : in  std_logic_vector(7 downto 0);    --! Length of a burst transfer input
         display_finished  : in  std_logic;                       --! Indicates when display is finished
         transfer_start    : out std_logic                        --! Indicates start of transfer
         
   ); 
end entity Master_Interface_DMA;
   
--============================================================================
--! Architectures                                                           --
--============================================================================

--! @brief      Architecture definition of the master interface
--! @details    Whenever the master receives the start signal from the slave, 
--!             the DMA master keeps reading data and sending it to the FIFO
--!             until it reaches the address of the last pixel stored. 
architecture rtl of Master_Interface_DMA is

   --! Constants -------------------------------------------------------------
   
   --! Image dimensions in pixels
   constant IMG_WIDTH      : natural := 320;
   constant IMG_HEIGHT     : natural := 240;
	constant BUFFER_LENGTH  : natural := IMG_WIDTH*IMG_HEIGHT*4;
   
   constant WORD_LENGTH    : natural := 32;

   --! Internal signals ------------------------------------------------------
   
   signal burst_cnt        : integer;
   signal burst_tot        : integer;
   signal start_address    : integer;
   signal current_address  : integer;
   signal end_address      : integer;
   
   --! States ----------------------------------------------------------------
   
   type MASTER_DMA_STATES is (
      INIT, IDLE, READ_REQUEST, READ_DATA, VERIFY_ADDRESS, WAIT_DISPLAY
   ); 
   
   signal state : MASTER_DMA_STATES;
   signal next_state  : MASTER_DMA_STATES;
   
   begin
      
      --! Read data from SDRAM
      
      FIFO_data(15 downto 11) <= am_readdata(15 downto 11);
      FIFO_data(10 downto 5)  <= am_readdata(10 downto 5);
      FIFO_data(4 downto 0)   <= am_readdata(4 downto 0);

      --! We want to empty the FIFO when in IDLE state
      FIFO_aclr <= '1' when state = IDLE else '0';
      
      
      -- FSM state transition logic ------------------------------------------
      
      state_logic: process(burst_cnt, state, start_in, burst_tot_in, am_waitrequest, FIFO_almost_full, current_address, nReset) is
      
         begin
         
            am_read <= '0';
            FIFO_wrreq       <= '0';
            am_address <= (others => '0');
            am_burstcount <= (others => '0');
            am_byteenable    <= "1111";
            
            if nReset = '0' then
               next_state <= INIT;
               
            else
            
               case state is
               
                  when INIT               => transfer_start <= '0';
                                             next_state       <= IDLE;
                                             
                                          
                  when IDLE               => if start_in = '1' then
                                                next_state <= READ_REQUEST;
                                             else
                                                next_state <= IDLE;
                                             end if;
                                             
                                             
                  when READ_REQUEST       => if FIFO_almost_full = '0' then
                                                am_address <= std_logic_vector(to_unsigned(current_address,am_address'length));
                                                am_burstcount <= std_logic_vector(to_unsigned(burst_tot,am_burstcount'length));
                                                am_read <= '1';
                                             end if;
                                             
                                             if am_waitrequest = '1' or FIFO_almost_full = '1' then
                                                next_state <= READ_REQUEST;
                                             elsif am_waitrequest = '0' and FIFO_almost_full = '0' then
                                                next_state <= READ_DATA;
                                             end if;
                                             
                                             
                  when READ_DATA          => if am_readdatavalid = '1' then
                                                FIFO_wrreq <= '1';
                                             end if;
                                             if burst_cnt < burst_tot then
                                                next_state <= READ_DATA;
                                             elsif burst_cnt = burst_tot then
                                                transfer_start <= '1';
                                                next_state <= VERIFY_ADDRESS;
                                             end if;
                                             
                                             
                  when VERIFY_ADDRESS     => if current_address = end_address then
                                                next_state <= WAIT_DISPLAY;
                                             else
                                                next_state <= READ_REQUEST;
                                             end if;
                                             
                                             
                  when WAIT_DISPLAY       => if display_finished = '1' then
                                                next_state <= INIT;
                                             else
                                                next_state <= WAIT_DISPLAY;
                                             end if;
               end case;
               
            end if;
            
         end process state_logic;
         
      -- FSM states inner processes ------------------------------------------

      process_logic: process(clk, nReset) is
      
         begin
         
            if nReset = '0' then
               burst_cnt <= 0;
               start_address <= 0;
               current_address <= 0;
               end_address <= 0;
               
            elsif rising_edge(clk) then
               
               burst_tot <= to_integer(unsigned(burst_tot_in));
               
               state <= next_state;
               
               case state is
               
                  when INIT               => burst_cnt <= 0;
                                             current_address <= 0;
                                             
                                             
                  when IDLE               => if start_in = '1' then
                                                current_address <= to_integer(unsigned(start_address_in));
                                                end_address <=  to_integer(unsigned(start_address_in)) + BUFFER_LENGTH - WORD_LENGTH;
                                             end if;
                                             
                                             
                  when READ_REQUEST       => if FIFO_almost_full = '0' then
                                                burst_cnt <= 0;
                                             end if;
                                             
                                             
                  when READ_DATA          => if am_readdatavalid = '1' then
                                                burst_cnt <= burst_cnt + 1;
                                             end if;
                                             
                                             
                  when VERIFY_ADDRESS     => burst_cnt <= 0;
                                             current_address <= current_address + 4*burst_tot;
                                             
                                             
                  when WAIT_DISPLAY       => null;
                  
               end case;
               
            end if;
            
         end process process_logic;
         
end architecture rtl;