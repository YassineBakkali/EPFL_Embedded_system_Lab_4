--============================================================================
--! @file   LCD_controller.vhd                                               -
--! @brief  Defines interconnections between components of LCD controller.   -
--============================================================================

--! Use standard library
library IEEE;

--! Use standard library
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--============================================================================
--! Entities                                                                 -
--============================================================================

entity LCD_controller is
   port (
      --! clock, resets
      nReset            : in  std_logic;
      clk               : in  std_logic;
      
      --! Avalon slave
      as_writedata      : in  std_logic_vector(31 downto 0);
      as_write          : in  std_logic;
      as_address        : in  std_logic_vector(2 downto 0);
      as_read           : in  std_logic;
      as_readdata       : out std_logic_vector(31 downto 0);

      --! Avalon master
      am_address        : out std_logic_vector(31 downto 0);
      am_burstcount     : out std_logic_vector(7 downto 0);
      am_readdata       : in  std_logic_vector(31 downto 0);
      am_readdatavalid  : in  std_logic;
      am_byteenable     : out std_logic_vector(3 downto 0);
      am_waitrequest    : in  std_logic;
      am_read           : out std_logic;
      
      --! LT24 signals
      LT24_Res_n        : out std_logic;
      LT24_CSX          : out std_logic;
      LT24_DCX          : out std_logic;
      LT24_WRX          : out std_logic;
      LT24_RDX          : out std_logic;
      LT24_D            : out std_logic_vector(15 downto 0);
      LT24_LCD_ON       : out std_logic
   
   );
end entity LCD_controller;

--============================================================================
--! Components                                                               -
--============================================================================

architecture struct of LCD_controller is

   --! Slave Interface ports -------------------------------------------------
   
   component Slave_Interface
      port (
         clk               : in std_logic;
         nReset            : in std_logic;

         as_writedata      : in  std_logic_vector(31 downto 0);
         as_write          : in  std_logic;
         as_address        : in  std_logic_vector(2 downto 0);
         as_read           : in  std_logic;
         as_readdata       : out std_logic_vector(31 downto 0);

         cmd_or_data       : out std_logic_vector(1 downto 0);
         cmd_data          : out std_logic_vector(15 downto 0);
         cmd_data_ready    : in  std_logic;
         lcd_on_out        : out std_logic;

         start_address_out : out std_logic_vector(31 downto 0);
         burst_tot_out     : out std_logic_vector(7 downto 0)
      );
   end component Slave_Interface;
   
   --! Master DMA Interface ports --------------------------------------------
   
   component Master_Interface_DMA
      port (
         clk               : in  std_logic;
         nReset            : in  std_logic;

         am_waitrequest    : in  std_logic;
         am_address        : out std_logic_vector(31 downto 0);
         am_read           : out std_logic;
         am_readdata       : in  std_logic_vector(31 downto 0);
         am_readdatavalid  : in  std_logic;
         am_burstcount     : out std_logic_vector(7 downto 0);
         am_byteenable     : out std_logic_vector(3 downto 0);
         
         FIFO_almost_full  : in  std_logic;
         FIFO_data         : out std_logic_vector(15 downto 0);
         FIFO_wrreq        : out std_logic;
         FIFO_aclr         : out  std_logic;

         start_in          : in  std_logic;
         start_address_in  : in  std_logic_vector(31 downto 0);
         burst_tot_in      : in  std_logic_vector(7 downto 0);
         display_finished  : in std_logic;
         transfer_start    : out std_logic
      );
   end component Master_Interface_DMA;
   
   
   --! LT24 Interface ports --------------------------------------------------
   
   component LT24_Interface
      port (
         clk               : in  std_logic;
         nReset            : in  std_logic;

         cmd_or_data       : in  std_logic_vector(1 downto 0);
         cmd_data          : in  std_logic_vector(15 downto 0);
         cmd_LCD_ON        : in  std_logic;

         LT24_CSX          : out std_logic;
         LT24_DCX          : out std_logic;
         LT24_D            : out std_logic_vector(15 downto 0);
         LT24_RDX          : out std_logic;
         LT24_WRX          : out std_logic;
         LT24_Res_n        : out std_logic;
         LT24_LCD_ON       : out std_logic;

         FIFO_empty        : in  std_logic;
         FIFO_q            : in  std_logic_vector(15 downto 0);
         FIFO_rdreq        : out std_logic;
         
         start_out         : out std_logic;
         
         display_finished  : out std_logic;
         
         transfer_start : in std_logic;

         cmd_data_ready    : out std_logic
      ); 
   end component LT24_Interface;
   
   --! FIFO entity ports ------------------------------------------------------
   
   component FIFO_entity
      port (
         clk               : in std_logic;
         nReset            : in std_logic;
         
         FIFO_aclr         : in std_logic;
         
         FIFO_data         : in  std_logic_vector(15 downto 0); -- data in
         FIFO_q            : out std_logic_vector(15 downto 0); -- data out
         
         FIFO_rdreq        : in  std_logic;
         FIFO_wrreq        : in  std_logic;
         
         FIFO_empty        : out  std_logic;
         FIFO_almost_full  : out  std_logic
      ); 
   end component FIFO_entity;
   
--============================================================================
--! Interconnections                                                         -
--============================================================================
   
   --! Signal used for interconnections
   
   signal iCMD_OR_DATA        : std_logic_vector(1 downto 0);
   signal iCMD_DATA           : std_logic_vector(15 downto 0);
   signal iCMD_DATA_READY     : std_logic;
   signal iCMD_LCD_ON         : std_logic;
   
   signal iSTART              : std_logic;
   signal iSTART_ADDRESS      : std_logic_vector(31 downto 0);
   signal iBURST_TOT          : std_logic_vector(7 downto 0);
   signal iDISPLAY_FINISHED   : std_logic;
   signal iTRANSFER_START     : std_logic;
   
   signal iFIFO_ACLR          : std_logic;
   signal iFIFO_DATA          : std_logic_vector(15 downto 0);
   signal iFIFO_Q             : std_logic_vector(15 downto 0);
   signal iFIFO_RDREQ         : std_logic;
   signal iFIFO_WRREQ         : std_logic;
   signal iFIFO_EMPTY         : std_logic;
   signal iFIFO_ALMOST_FULL   : std_logic;
   

   begin
   
      --! Slave Interface interconnections -----------------------------------
      
      Slave_interface_inst : Slave_Interface
         port map (
            clk               => clk,
            nReset            => nReset,

            as_writedata      => as_writedata,
            as_write          => as_write,
            as_address        => as_address,
            as_read           => as_read,
            as_readdata       => as_readdata,

            cmd_or_data       => iCMD_OR_DATA,
            cmd_data          => iCMD_DATA,
            cmd_data_ready    => iCMD_DATA_READY,
            lcd_on_out        => iCMD_LCD_ON,

            start_address_out => iSTART_ADDRESS,
            burst_tot_out     => iBURST_TOT
         
         );
         
      --! Master DMA Interface interconnections ------------------------------
         
      Master_Interface_DMA_inst : Master_Interface_DMA
         port map (
            clk               => clk,
            nReset            => nReset,

            am_waitrequest    => am_waitrequest,
            am_address        => am_address,
            am_read           => am_read,
            am_readdata       => am_readdata,
            am_readdatavalid  => am_readdatavalid,
            am_burstcount     => am_burstcount,
            am_byteenable     => am_byteenable,
            
            FIFO_almost_full  => iFIFO_ALMOST_FULL,
            FIFO_data         => iFIFO_DATA,
            FIFO_wrreq        => iFIFO_WRREQ,
            FIFO_aclr         => iFIFO_ACLR,

            start_in          => iSTART,
            start_address_in  => iSTART_ADDRESS,
            burst_tot_in      => iBURST_TOT,
            display_finished  => iDISPLAY_FINISHED,
            transfer_start    => iTRANSFER_START
         
         );

      --! LT24 Interface interconnections ------------------------------------
      
      LT24_Interface_inst : LT24_Interface
         port map (
            clk               => clk,
            nReset            => nReset,

            cmd_or_data       => iCMD_OR_DATA,
            cmd_data          => iCMD_DATA,

            LT24_CSX          => LT24_CSX,
            LT24_DCX          => LT24_DCX,
            LT24_D            => LT24_D,
            LT24_RDX          => LT24_RDX,
            LT24_WRX          => LT24_WRX,
            LT24_Res_n        => LT24_Res_n,
            LT24_LCD_ON       => LT24_LCD_ON,
            cmd_LCD_ON        => iCMD_LCD_ON,

            FIFO_empty        => iFIFO_EMPTY,
            FIFO_q            => iFIFO_Q,
            FIFO_rdreq        => iFIFO_RDREQ,
            
            start_out         => iSTART,
            
            display_finished  => iDISPLAY_FINISHED,
            
            transfer_start    => iTRANSFER_START,

            cmd_data_ready    => iCMD_DATA_READY
         );
         
      --! FIFO entity interconnections ---------------------------------------
      
      FIFO_entity_inst : FIFO_entity
         port map (
            clk               => clk,
            nReset            => nReset,
            
            FIFO_aclr         => iFIFO_ACLR,
            
            FIFO_data         => iFIFO_DATA,
            FIFO_q            => iFIFO_Q,
            
            FIFO_rdreq        => iFIFO_RDREQ,
            FIFO_wrreq        => iFIFO_WRREQ,
            
            FIFO_empty        => iFIFO_EMPTY,
            FIFO_almost_full  => iFIFO_ALMOST_FULL
         
         );

end architecture struct;
