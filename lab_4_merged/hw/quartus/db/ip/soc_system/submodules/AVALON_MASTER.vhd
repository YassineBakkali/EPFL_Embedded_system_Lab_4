LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY D5M_MASTER IS
	PORT (
		csi_clk : IN STD_LOGIC;
		rsi_reset_n : IN STD_LOGIC;

		--with Camera Interface
		DATA_i : IN STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);
		BUFFER_FIFO_EMPTY_i : IN STD_LOGIC;
		BUFFER_FIFO_RREQ_o : OUT STD_LOGIC;

		--with Avalon Slave
		frame_sent_o : OUT STD_LOGIC := '0';
		start_address_i : IN STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);
		data_length_i : IN STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);

		-- Avalon master interface
		avm_m0_address : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		avm_m0_writedata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		avm_m0_write : OUT STD_LOGIC;
		avm_m0_waitrequest : IN STD_LOGIC;
		avm_m0_byteenable : OUT STD_LOGIC_VECTOR(4-1 DOWNTO 0)
	);

END D5M_MASTER;

ARCHITECTURE comp1 OF D5M_MASTER IS
	--states
	TYPE Mas_State IS (IDLE, WAITING_DATA, WAITING_WRITE);
	SIGNAL STATE : Mas_State := IDLE;

	-- internal signals
	SIGNAL startAddr_bridge : STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);
	SIGNAL datalength_bridge : STD_LOGIC_VECTOR(32 - 1 DOWNTO 0) := x"0004B000";
	
BEGIN

	--SIGNALS
	avm_m0_byteenable <= b"1111"; --always write 32 bits at a time
	
	--FSM PROCESS
	PROCESS (csi_clk, rsi_reset_n, start_address_i, data_length_i)
	BEGIN
		IF rsi_reset_n = '1' THEN
			IF rising_edge(csi_clk) THEN
				CASE STATE IS
					WHEN IDLE =>
						IF unsigned(data_length_i) > 0 THEN
							STATE <= WAITING_DATA;
							datalength_bridge <= data_length_i;
							startAddr_bridge <= start_address_i;
						END IF;
					WHEN WAITING_DATA =>
						frame_sent_o <= '0';
						IF unsigned(data_length_i) = 0 THEN
							STATE <= IDLE;
						ELSIF BUFFER_FIFO_EMPTY_i = '0' THEN -- if FIFO is not empty, it changes states to try to write it
							STATE <= WAITING_WRITE;
							avm_m0_address <= startAddr_bridge;
							avm_m0_write <= '1';
							avm_m0_writedata <= DATA_i;
						END IF;
					WHEN WAITING_WRITE => 
						IF unsigned(datalength_bridge) /= 0 THEN
							IF BUFFER_FIFO_EMPTY_i = '0' THEN -- while FIFO is not empty, it tries to write to the avalon bus
								avm_m0_write <= '1';
								avm_m0_address <= startAddr_bridge;
								avm_m0_writedata <= DATA_i;
								IF avm_m0_waitrequest = '0' THEN --it acknowledges that the data is sent prepares the next data
									BUFFER_FIFO_RREQ_o <= '1';
									startAddr_bridge <= std_logic_vector(unsigned(startAddr_bridge) + 4);
									datalength_bridge <= std_logic_vector(unsigned(datalength_bridge) - 4);
								ELSE
									BUFFER_FIFO_RREQ_o <= '0';
								END IF;
							ELSE -- FIFO is empty
								STATE <= WAITING_DATA;
								avm_m0_write <= '0';
								BUFFER_FIFO_RREQ_o <= '0';
							END IF;
							frame_sent_o <= '0';
						ELSE --it has finished writing a full image, loads new address and length
							STATE <= WAITING_DATA;
							startAddr_bridge <= start_address_i;
							datalength_bridge <= data_length_i;
							avm_m0_write <= '0';
							BUFFER_FIFO_RREQ_o <= '0';
							frame_sent_o <= '1';
						END IF;
				END CASE;
			END IF;
		ELSE
			--reset condition, default values
			STATE <= IDLE;
			BUFFER_FIFO_RREQ_o <= '0';
			startAddr_bridge <= (OTHERS => '0');
			datalength_bridge <= x"0004B000";
			avm_m0_write <= '0';
			frame_sent_o <= '0';
		END IF;
	END PROCESS;
	
END comp1;
