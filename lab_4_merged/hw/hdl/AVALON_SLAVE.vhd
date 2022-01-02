LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY D5M_SLAVE IS
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
		
		--with cam interface
		start_o : OUT STD_LOGIC;
		stop_o : OUT STD_LOGIC
	);

END D5M_SLAVE;

ARCHITECTURE comp0 OF D5M_SLAVE IS
	-- internal signals
	SIGNAL frameSent : STD_LOGIC := '0';
	
	
	--internal registers
	SIGNAL iCamAddr : STD_LOGIC_VECTOR(32-1 DOWNTO 0);
	SIGNAL iCamLength : STD_LOGIC_VECTOR(32-1 DOWNTO 0);
	SIGNAL iCamStart : STD_LOGIC_VECTOR(8-1 DOWNTO 0);
	SIGNAL iCamStop : STD_LOGIC_VECTOR(8-1 DOWNTO 0);
	SIGNAL iCamSnapshot : STD_LOGIC_VECTOR(8-1 DOWNTO 0);
	SIGNAL iFrameSent : STD_LOGIC_VECTOR(8-1 DOWNTO 0);
	
	SIGNAL FrameSent_rst : STD_LOGIC := '0';
	
	

BEGIN

	--SIGNALS
	start_address_o <= iCamAddr;
	data_length_o <= iCamLength;
	start_o <= iCamStart(0);
	stop_o <= iCamStop(0);
	--iFrameSent(0) <= FrameSent_set or FrameSent_slv;
	--iFrameSent(8-1 DOWNTO 1) <= (OTHERS => '0');
	
	--FrameSent reciever
	PROCESS (csi_clk, rsi_reset_n, frame_sent_i)
	BEGIN
		IF rsi_reset_n = '1' THEN
			IF rising_edge(csi_clk) THEN
				IF frame_sent_i = '1' THEN
					iFrameSent <= x"01";
				ELSIF FrameSent_rst = '1' THEN
					iFrameSent <= x"00";
				END IF;
			END IF;
		ELSE
			iFrameSent <= x"00";
		END IF;
	END PROCESS;
	
	-- Avalon slave write to registers.
	PROCESS (csi_clk, rsi_reset_n)
	BEGIN
		IF rsi_reset_n = '0' THEN
		-- default values
			iCamAddr <= x"00000000"; 
			iCamLength <= x"0004B000";
			iCamStart <= x"00"; 
			iCamStop <= x"00";
			iCamSnapshot <= x"00";
		ELSIF rising_edge(csi_clk) THEN
			IF avs_s0_write = '1' THEN
				CASE avs_s0_address IS
					WHEN "0000" => iCamAddr <= avs_s0_writedata;
					WHEN "0001" => iCamLength <= avs_s0_writedata;
					WHEN "0010" => iCamStart <= avs_s0_writedata(8-1 DOWNTO 0);
					WHEN "0011" => iCamStop <= avs_s0_writedata(8-1 DOWNTO 0);
					WHEN "0100" => iCamSnapshot <= avs_s0_writedata(8-1 DOWNTO 0);
					WHEN OTHERS => NULL;
				END CASE;
			END IF;
		END IF;
	END PROCESS;

	-- Avalon slave read from registers.
	PROCESS (csi_clk, rsi_reset_n)
	BEGIN
		IF rsi_reset_n = '1' THEN
			IF rising_edge(csi_clk) THEN
				avs_s0_readdata <= (OTHERS => '0');
				IF avs_s0_read = '1' THEN
					CASE avs_s0_address IS
						WHEN "0000" => avs_s0_readdata <= iCamAddr;
						WHEN "0001" => avs_s0_readdata <= iCamLength;
						WHEN "0010" => avs_s0_readdata <= std_logic_vector(resize(unsigned(iCamStart),32));
						WHEN "0011" => avs_s0_readdata <= std_logic_vector(resize(unsigned(iCamStop),32));
						WHEN "0100" => avs_s0_readdata <= std_logic_vector(resize(unsigned(iCamSnapshot),32));
						WHEN "0101" => avs_s0_readdata <=
							std_logic_vector(resize(unsigned(iFrameSent),32));
							FrameSent_rst <= '1';
						WHEN OTHERS => NULL;
					END CASE;
				ELSE
					FrameSent_rst <= '0';
				END IF;
			END IF;
		ELSE
			-- default values
			FrameSent_rst <= '0';
		END IF;
	END PROCESS;

END comp0;