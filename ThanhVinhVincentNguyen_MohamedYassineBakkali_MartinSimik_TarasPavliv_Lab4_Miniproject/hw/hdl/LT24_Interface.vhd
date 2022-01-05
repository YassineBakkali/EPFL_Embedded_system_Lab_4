--============================================================================
--! @file   LT24_Interface.vhd                                               -
--! @brief  Handles communication with ILI9341 driver                        -
--!         following 8080 I protocol.                                       -
--============================================================================

--! Use standard library
library IEEE;

--! Use logic elements
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--============================================================================
--! Entities                                                                 -
--============================================================================

entity LT24_Interface is
   port (  
      --! clock, resets
      clk         :  in std_logic;
      nReset      :  in std_logic;
      
      --! 01 write command
      --! 10 write data
      --! 00 no operation
      cmd_or_data :  in std_logic_vector(1 downto 0);
      
      --! contains the command/data to write
      --! to start displaying data, cmd_data = '2C'
      cmd_data    :  in std_logic_vector(15 downto 0);
      
      --! command to turn ON or OFF the LCD
      cmd_LCD_ON  :  in std_logic;
      
      --! LT24 signals
      LT24_CSX    :  out std_logic;
      LT24_DCX    :  out std_logic;
      LT24_D      :  out std_logic_vector(15 downto 0);
      LT24_RDX    :  out std_logic;
      LT24_WRX    :  out std_logic;
      LT24_Res_n  :  out std_logic;
      LT24_LCD_ON :  out std_logic;
      
      --! FIFO signals
      FIFO_empty  :  in std_logic;
      FIFO_q      :  in std_logic_vector(15 downto 0);
      FIFO_rdreq  :  out std_logic;
      
      --! Requests the master to begin the data transfer
      start_out   :  out std_logic;
      
      display_finished : out std_logic;
      
      transfer_start : in std_logic;
      
      --! '1' if writing cmd/data or displaying is completed
      cmd_data_ready : out std_logic      
   );
end entity LT24_Interface;


--============================================================================
--! Finite state machine                                                     -
--============================================================================

--! @brief     Architecture definition of the LT24 Interface.
--! @details   Handles communication with ILI9341 driver, following 8080-I 
--!            protocol. This module sends data from the FIFO or commands/data
--!            from the Avalon slave to the LT24. When the image is fully 
--!            displayed or the command has finished its execution, it sends
--!            back a confirmation pulse (cmd_data_ready).

architecture rtl of LT24_Interface is

   --! Constants -------------------------------------------------------------

   --! Command or data aliases
   constant TYPE_CMD       : std_logic_vector(1 downto 0) := "01";
   constant TYPE_DATA      : std_logic_vector(1 downto 0) := "10";
   constant TYPE_NO_OP     : std_logic_vector(1 downto 0) := "00";

   --! List of commands
   constant CMD_DISPLAY    : std_logic_vector(7 downto 0) := x"2C";

   --! Image dimensions in pixels
   constant IMG_WIDTH      : positive := 320;
   constant IMG_HEIGHT     : positive := 240;

   --! Number of words per image
   constant IMG_WORD_LEN   : positive := IMG_WIDTH*IMG_HEIGHT;

   --! Internal signals ------------------------------------------------------

   --! Used to generate proper delays following 8080 I protocol
   signal cnt_cycles       : natural range 0 to 5;

   --! Keep track of the number of pixels displayed
   signal cnt              : natural range 0 to IMG_WORD_LEN;


   --! States ----------------------------------------------------------------
   
   type LT24_STATES is (
      INIT, 
      WRITE_CMD, WRITE_DATA, DISPLAY, WAIT_TRANSFER, 
      CHECK_FIFO, CHECK_TRANSFER
   );

   signal state: LT24_STATES;

   begin
      
      
      --! State logic (FSM) --------------------------------------------------
      
      state_logic : process(nReset, clk) is
      
         begin
         
            if nReset = '0' then
            
               state          <= INIT;
               cnt            <= 0;
               cnt_cycles     <= 0;
               cmd_data_ready <= '0';
               display_finished <='0';
               
               LT24_CSX       <= '1';
               LT24_DCX       <= '1';
               LT24_RDX       <= '1';
               LT24_WRX       <= '1';
               LT24_D         <= (others => 'Z');
               LT24_Res_n     <= '0';
               
            elsif rising_edge(clk) then
               
               LT24_LCD_ON    <= cmd_LCD_ON;
               start_out      <= '0';
               
               case state is
               
                  when INIT            => cnt         <= 0;
                                          cnt_cycles  <= 0;
                                          
                                          LT24_Res_n  <= '1';
                                          LT24_CSX    <= '1';
                                          LT24_DCX    <= '1';
                                          LT24_RDX    <= '1';
                                          LT24_WRX    <= '1';
                                          LT24_D         <= (others => 'Z');
                                          
                                          cmd_data_ready <= '0';
                                          display_finished <= '0';
                                          FIFO_rdreq  <= '0';
                                          
                                          if cmd_or_data = TYPE_CMD then
                                             state <= WRITE_CMD;
                                          elsif cmd_or_data = TYPE_DATA then
                                             state <= WRITE_DATA;
                                          end if;
                                          
                  
                  when WRITE_CMD       => -- ___         ___________  CSX
                                          --    \_______/
                                          -- ___         ___________  DCX
                                          --    \_______/
                                          -- ___     _______________  WRX
                                          --    \___/    
                                          -- ___ _______ ___________  D
                                          -- ___╳_______╳___________
                                          --         _______
                                          -- _______/       \_______  cmd_data_ready
                                          --             ___
                                          -- ___________/   \_______  state_ready
                                          --
                                          --    0   1   2   3   4     cnt_cycles
                                          -- ---+---+---+---+---+---

                                          cnt_cycles <= cnt_cycles + 1;
                                          case cnt_cycles is
                                             when 0 =>
                                                LT24_CSX    <= '0';
                                                LT24_DCX    <= '0';  
                                                LT24_WRX    <= '0';
                                                LT24_D      <= cmd_data;
                                             when 1 =>
                                                LT24_WRX    <= '1';
                                                if cmd_data(7 downto 0) /= CMD_DISPLAY then
                                                   cmd_data_ready <= '1';
                                                end if;
                                             when 2 =>
                                                LT24_DCX    <= '1';
                                                LT24_CSX    <= '1';
                                                LT24_D      <= (others => 'Z');
                                                if cmd_data(7 downto 0) = CMD_DISPLAY then
                                                   start_out <= '1';
                                                end if;
                                             when others =>
                                                start_out <= '0';
                                                cnt_cycles  <= 0; 
                                                
                                                cmd_data_ready <= '0';
                                                   if cmd_data(7 downto 0) = CMD_DISPLAY then
                                                      cmd_data_ready <= '1';
                                                      state <= WAIT_TRANSFER;
                                                   else
                                                      state <= INIT;
                                                   end if;
                                          end case;

                                                            
                  when WRITE_DATA      => -- ___         ___________  CSX
                                          --    \_______/
                                          -- _______________________  DCX
                                          --    
                                          -- ___     _______________  WRX
                                          --    \___/    
                                          -- ___ _______ ___________  D
                                          -- ___╳_______╳___________
                                          --         _______
                                          -- _______/       \_______  cmd_data_ready
                                          --             ___
                                          -- ___________/   \_______  state_ready                                          
                                          --
                                          --    0   1   2   3   4     cnt_cycles
                                          -- ---+---+---+---+---+---

                                          cnt_cycles <= cnt_cycles + 1;
                                          case cnt_cycles is
                                             when 0 =>

                                                LT24_CSX    <= '0';
                                                LT24_DCX    <= '1';  
                                                LT24_WRX    <= '0';
                                                LT24_D      <= cmd_data;
                                             when 1 =>
                                                LT24_WRX    <= '1';
                                                cmd_data_ready <= '1';
                                             when 2 =>
                                                LT24_DCX    <= '1';
                                                LT24_CSX    <= '1';
                                                LT24_D      <= (others => 'Z');
                                             when others =>
                                                cmd_data_ready <= '0';
                                                cnt_cycles  <= 0; 
                                                state <= INIT;
                                          end case;
                                                                           
                  
                  when DISPLAY         => -- ___________         ___________  CSX
                                          --            \_______/
                                          -- _______________________________  DCX
                                          --    
                                          -- ___________     _______________  WRX
                                          --            \___/    
                                          -- ___________ _______ ___________  D
                                          -- ___________╳_______╳___________
                                          --     ___
                                          -- ___/   \_______________________  FIFO_rdreq
                                          --                     ___
                                          -- ___________________/   \_______  state_ready
                                          --
                                          --   -1   0   1   2   3   4   5     cnt_cycles
                                          -- ---+---+---+---+---+---+---+---
                  
                                          cnt_cycles <= cnt_cycles + 1;
                                          case cnt_cycles is
                                             when 0 =>
                                                FIFO_rdreq  <= '0';
                                             when 1 =>
                                                LT24_CSX    <= '0';
                                                LT24_DCX    <= '1';  
                                                LT24_WRX    <= '0';
                                                
                                                LT24_D      <= FIFO_q;

                                             when 2 =>
                                                LT24_WRX    <= '1';
                                             when 3 =>
                                                LT24_DCX    <= '1';
                                                LT24_CSX    <= '1';
                                                LT24_D      <= (others => 'Z');
                                             when others =>
                                                cnt_cycles  <= 0; 
                                                state <= CHECK_TRANSFER;
                                          end case;
                                          
                                             
                  when WAIT_TRANSFER   => if transfer_start = '0' then
                                             state <= WAIT_TRANSFER;
                                          else
                                             state <= CHECK_FIFO;
                                          end if;
                                          
                  
                  when CHECK_FIFO      => if FIFO_empty = '0' then
                                             state <= DISPLAY;
                                             FIFO_rdreq  <= '1';
                                          end if;
                                          cmd_data_ready <= '0';
                  
                  
                  when CHECK_TRANSFER  => cnt <= cnt + 1;
                                                           
                                          if cnt = IMG_WORD_LEN - 1 then
                                             cmd_data_ready <= '1';
                                             display_finished <= '1';
                                             state <= INIT;
                                          elsif FIFO_empty = '1' then
                                             state <= CHECK_FIFO;
                                          elsif FIFO_empty = '0' then
                                             FIFO_rdreq  <= '1';
                                             state <= DISPLAY;
                                          end if;
                  
                                                                                    
                  when others          => null;
                  
               end case;
               
            end if;
            
      end process state_logic;

end architecture rtl;