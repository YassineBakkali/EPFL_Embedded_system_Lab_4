--============================================================================
--! @file   FIFO_entity.vhd                                                  -
--! @brief  Redefines FIFO signals.                                          -
--============================================================================

--! Use standard library
library IEEE;

--! Use standard library
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--============================================================================
--! Entities                                                                 -
--============================================================================

entity FIFO_entity is
   port (
      clk               : in std_logic;
      nReset            : in std_logic;
      
      FIFO_aclr         : in std_logic;
      
      FIFO_data         : in  std_logic_vector(15 downto 0); -- data in
      FIFO_q            : out std_logic_vector(15 downto 0); -- data out
      
      FIFO_rdreq        : in  std_logic;
      FIFO_wrreq        : in  std_logic;
      
      FIFO_empty        : out std_logic;
      FIFO_almost_full  : out std_logic
   );
end entity FIFO_entity;

--============================================================================
--! Architectures                                                           --
--============================================================================

--! @brief      Architecture definition of FIFO entity
architecture struct of FIFO_entity is

   component FIFO
      port (
         aclr           : in  std_logic;
         clock          : in  std_logic;
         data           : in  std_logic_vector(15 downto 0);
         rdreq          : in  std_logic;
         wrreq          : in  std_logic;
         empty          : out std_logic;
         almost_full    : out std_logic;
         q              : out std_logic_vector(15 downto 0)
      );
   end component FIFO;
   
   signal FIFO_reset : std_logic;
   
   begin
      
      --! Active high
      FIFO_reset <= not(nReset) or FIFO_aclr;
      
      FIFO_inst : FIFO
         port map (
            aclr           => FIFO_reset,
            clock          => clk,
            data           => FIFO_data,
            rdreq          => FIFO_rdreq,
            wrreq          => FIFO_wrreq,
            empty          => FIFO_empty,
            almost_full    => FIFO_almost_full,
            q              => FIFO_q
         );
         
end architecture struct;