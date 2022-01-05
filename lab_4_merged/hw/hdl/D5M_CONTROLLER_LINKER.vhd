LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;


--Just links all components together

ENTITY D5M_CONTROLLER_LINKER IS
	PORT (
		csi_clk : IN STD_LOGIC;
		rsi_reset_n : IN STD_LOGIC;

		-- with Camera
		GPIO_1_D5M_D : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		GPIO_1_D5M_FVAL : IN STD_LOGIC;
		GPIO_1_D5M_LVAL : IN STD_LOGIC;
		GPIO_1_D5M_PIXCLK : IN STD_LOGIC;
		GPIO_1_D5M_RESET_N : OUT STD_LOGIC;
		--GPIO_1_D5M_TRIGGER : out   std_logic;
		GPIO_1_D5M_XCLKIN : OUT STD_LOGIC;
		
		-- Internal interface (i.e. Avalon slave).
		avs_s0_address : IN STD_LOGIC_VECTOR(4-1 DOWNTO 0);
		avs_s0_write : IN STD_LOGIC;
		avs_s0_read : IN STD_LOGIC;
		avs_s0_writedata : IN STD_LOGIC_VECTOR(32-1 DOWNTO 0);
		avs_s0_readdata : OUT STD_LOGIC_VECTOR(32-1 DOWNTO 0);
		
		-- Avalon master interface
		avm_m0_address : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		avm_m0_writedata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		avm_m0_write : OUT STD_LOGIC;
		avm_m0_waitrequest : IN STD_LOGIC;
		avm_m0_byteenable : OUT STD_LOGIC_VECTOR(4-1 DOWNTO 0)
	);

END D5M_CONTROLLER_LINKER;

ARCHITECTURE comp2 OF D5M_CONTROLLER_LINKER IS
	--CAM INTERFACE
	component D5M_CONTROLLER IS
	PORT (
		csi_clk : IN STD_LOGIC;
		rsi_reset_n : IN STD_LOGIC;
		
		-- External interface (i.e. conduit).
		GPIO_1_D5M_D       : in    std_logic_vector(11 downto 0);
	        GPIO_1_D5M_FVAL    : in    std_logic;
	        GPIO_1_D5M_LVAL    : in    std_logic;
	        GPIO_1_D5M_PIXCLK  : in    std_logic;
		
		--with Camera interface
		start_i : in STD_LOGIC;
		stop_i : in STD_LOGIC;
		
		--with Avalon master
		DATA_o : OUT STD_LOGIC_VECTOR(32-1 DOWNTO 0);
		BUFFER_FIFO_EMPTY_o : OUT STD_LOGIC;
		BUFFER_FIFO_RREQ_i : IN STD_LOGIC
	);
	END component;

	--SLAVE AVALON
	component D5M_SLAVE IS
	PORT (
		csi_clk : IN STD_LOGIC;
		rsi_reset_n : IN STD_LOGIC;
		
		-- Internal interface (i.e. Avalon slave).
		avs_s0_address : IN STD_LOGIC_VECTOR(4-1 DOWNTO 0);
		avs_s0_write : IN STD_LOGIC;
		avs_s0_read : IN STD_LOGIC;
		avs_s0_writedata : IN STD_LOGIC_VECTOR(32-1 DOWNTO 0);
		avs_s0_readdata : OUT STD_LOGIC_VECTOR(32-1 DOWNTO 0); -- TODO Attentien ^^'
		
		--with Avalon Master
		frame_sent_i : IN STD_LOGIC;
		start_address_o : OUT STD_LOGIC_VECTOR(32-1 DOWNTO 0);
		data_length_o : OUT STD_LOGIC_VECTOR(32-1 DOWNTO 0);

		--with Camera interface
		start_o : OUT STD_LOGIC;
		stop_o : OUT STD_LOGIC
	);
	END component;
	
	
	COMPONENT D5M_MASTER IS
	--MASTER AVALON
		PORT (
		csi_clk : IN STD_LOGIC;
		rsi_reset_n : IN STD_LOGIC;

		--with Camera Interface
		DATA_i : IN STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);
		BUFFER_FIFO_EMPTY_i : IN STD_LOGIC;
		BUFFER_FIFO_RREQ_o : OUT STD_LOGIC;

		--with Avalon Slave
		frame_sent_o : OUT STD_LOGIC;
		start_address_i : IN STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);
		data_length_i : IN STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);

		-- Avalon master interface
		avm_m0_address : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		avm_m0_writedata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		avm_m0_write : OUT STD_LOGIC;
		avm_m0_waitrequest : IN STD_LOGIC;
		avm_m0_byteenable : OUT STD_LOGIC_VECTOR(4-1 DOWNTO 0)
	);

	END component;

	--SIGNALS
	--Avalon Master - Camera Interface
	SIGNAL DATA_sig : STD_LOGIC_VECTOR(32 - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL BUFFER_FIFO_EMPTY_sig : STD_LOGIC := '0';
	SIGNAL BUFFER_FIFO_RREQ_sig : STD_LOGIC := '0';

	--Avalon Master - Avalon Slave
	SIGNAL frame_sent_sig : STD_LOGIC := '0';
	SIGNAL start_address_sig : STD_LOGIC_VECTOR(32 - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL data_length_sig : STD_LOGIC_VECTOR(32 - 1 DOWNTO 0) := (OTHERS => '0');

	--Avalon Slave - Camera Interface
	SIGNAL start_sig : STD_LOGIC := '0';
	SIGNAL stop_sig : STD_LOGIC := '0';
	
	
BEGIN
	--SIGNALS
	GPIO_1_D5M_RESET_N <= rsi_reset_n;
	GPIO_1_D5M_XCLKIN <= csi_clk;
	--PORT MAPS
	CAM_INTERFACE_inst : COMPONENT D5M_CONTROLLER PORT MAP (
		csi_clk => csi_clk,
		rsi_reset_n => rsi_reset_n,
		
		--with the camera (conduits)
		GPIO_1_D5M_D => GPIO_1_D5M_D,
      		GPIO_1_D5M_FVAL => GPIO_1_D5M_FVAL,
      		GPIO_1_D5M_LVAL => GPIO_1_D5M_LVAL,
      		GPIO_1_D5M_PIXCLK => GPIO_1_D5M_PIXCLK,
      		
      		--with Avalon Slave
		start_i => start_sig,
		stop_i => stop_sig,
		
		--with Avalon Master
		DATA_o => DATA_sig,
		BUFFER_FIFO_EMPTY_o => BUFFER_FIFO_EMPTY_sig,
		BUFFER_FIFO_RREQ_i => BUFFER_FIFO_RREQ_sig
	);


	D5M_SLAVE_inst : COMPONENT D5M_SLAVE PORT MAP (
		csi_clk => csi_clk,
		rsi_reset_n => rsi_reset_n,
		
		-- Avalon slave interface
		avs_s0_address  => avs_s0_address,
		avs_s0_write  => avs_s0_write,
		avs_s0_read  => avs_s0_read,
		avs_s0_writedata  => avs_s0_writedata,
		avs_s0_readdata  => avs_s0_readdata,
		
		--with Avalon Master
		frame_sent_i  => frame_sent_sig,
		start_address_o  => start_address_sig,
		data_length_o  => data_length_sig,

		--with camera interface
		start_o  => start_sig,
		stop_o  => stop_sig
	);

	D5M_MASTER_inst : COMPONENT D5M_MASTER PORT MAP (
		csi_clk => csi_clk,
		rsi_reset_n => rsi_reset_n,

		--with Camera Interface
		DATA_i => DATA_sig,
		BUFFER_FIFO_EMPTY_i => BUFFER_FIFO_EMPTY_sig,
		BUFFER_FIFO_RREQ_o => BUFFER_FIFO_RREQ_sig,

		--with Avalon Slave
		frame_sent_o => frame_sent_sig,
		start_address_i => start_address_sig,
		data_length_i => data_length_sig,

		-- Avalon master interface
		avm_m0_address => avm_m0_address,
		avm_m0_writedata => avm_m0_writedata,
		avm_m0_write => avm_m0_write,
		avm_m0_waitrequest => avm_m0_waitrequest,
		avm_m0_byteenable => avm_m0_byteenable
	);

END comp2;
