LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY D5M_CONTROLLER IS
	PORT (
		-- with Camera
		GPIO_1_D5M_D : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		GPIO_1_D5M_FVAL : IN STD_LOGIC;
		GPIO_1_D5M_LVAL : IN STD_LOGIC;
		GPIO_1_D5M_PIXCLK : IN STD_LOGIC;
		--GPIO_1_D5M_RESET_N : OUT STD_LOGIC;
		--GPIO_1_D5M_TRIGGER : out   std_logic;
		--GPIO_1_D5M_XCLKIN : OUT STD_LOGIC;

		--with Avalon slave
		csi_clk : IN STD_LOGIC;
		rsi_reset_n : IN STD_LOGIC;
		start_i : IN STD_LOGIC;
		stop_i : IN STD_LOGIC;

		--with Avalon master
		DATA_o : OUT STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);
		BUFFER_FIFO_EMPTY_o : OUT STD_LOGIC;
		BUFFER_FIFO_RREQ_i : IN STD_LOGIC
	);

END D5M_CONTROLLER;

ARCHITECTURE comp OF D5M_CONTROLLER IS
	--states
	TYPE Int_State IS (IDLE, BUSY);
	SIGNAL STATE : Int_State := IDLE;
	-- internal signals
	SIGNAL start_sig : STD_LOGIC := '0';
	SIGNAL stop_sig : STD_LOGIC := '1';

	--BAYER FIFO SIGNAL
	SIGNAL q_sig : STD_LOGIC_VECTOR (11 DOWNTO 0);
	SIGNAL usedw_sig : STD_LOGIC_VECTOR (9 DOWNTO 0);

	SIGNAL data_bridge : STD_LOGIC_VECTOR (12 - 1 DOWNTO 0);
	--Cam interface
	SIGNAL pixel_valid : STD_LOGIC := '0';
	SIGNAL valid_row : STD_LOGIC := '1';
	SIGNAL downsampling_row_counter : UNSIGNED(12 - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL downsampling_col_counter : UNSIGNED(2 - 1 DOWNTO 0) := (OTHERS => '0');
	--BUFFER FIFO
	SIGNAL rdusedw_sig : STD_LOGIC_VECTOR(9 - 1 DOWNTO 0);

	COMPONENT Bayer_FIFO IS
		PORT (
			aclr : IN STD_LOGIC;
			clock : IN STD_LOGIC;
			data : IN STD_LOGIC_VECTOR (11 DOWNTO 0);
			rdreq : IN STD_LOGIC;
			wrreq : IN STD_LOGIC;
			q : OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
			usedw : OUT STD_LOGIC_VECTOR (9 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT Buffer_FIFO IS
		PORT (
			aclr : IN STD_LOGIC;
			data : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			rdclk : IN STD_LOGIC;
			rdreq : IN STD_LOGIC;
			wrclk : IN STD_LOGIC;
			wrreq : IN STD_LOGIC;
			q : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			rdempty : OUT STD_LOGIC;
			rdusedw : OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
		);
	END COMPONENT;

	--DEBAYERING
	SIGNAL fifo_clr : STD_LOGIC := '0';
	SIGNAL bayer_fifo_push : STD_LOGIC := '0';-- was 1 TODO
	SIGNAL bayer_fifo_pop : STD_LOGIC := '0';
	SIGNAL push_state : STD_LOGIC := '1';
	SIGNAL color_ready : STD_LOGIC := '0';
	SIGNAL output_color : UNSIGNED(32 - 1 DOWNTO 0) := (OTHERS => '0');

	--BUFFER FIFO
	SIGNAL buffer_write : STD_LOGIC := '0';

BEGIN
	--COMPONENT PORTMAP (INT)
	Bayer_FIFO_inst : COMPONENT Bayer_FIFO PORT MAP(
		aclr => fifo_clr,
		clock => GPIO_1_D5M_PIXCLK,
		data => data_bridge,
		rdreq => bayer_fifo_pop,
		wrreq => bayer_fifo_push, --pushes data in bayer fifo
		q => q_sig,
		usedw => usedw_sig
	);
	Buffer_FIFO_inst : COMPONENT Buffer_FIFO PORT MAP(
		aclr => fifo_clr,
		data => STD_LOGIC_VECTOR(output_color),
		rdclk => csi_clk,
		rdreq => BUFFER_FIFO_RREQ_i,
		wrclk => GPIO_1_D5M_PIXCLK,
		wrreq => buffer_write,
		q => DATA_o,
		rdempty => BUFFER_FIFO_EMPTY_o,
		rdusedw => rdusedw_sig
	);

	--SIGNALS
	--GPIO_1_D5M_RESET_N <= rsi_reset_n;
	--GPIO_1_D5M_XCLKIN <= csi_clk;
	fifo_clr <= '1' WHEN rsi_reset_n = '0' OR STATE = IDLE ELSE
		'0';
	bayer_fifo_push <= push_state AND pixel_valid;
	bayer_fifo_pop <= NOT(push_state) AND pixel_valid;
	--start_sig <= start and not(stop);
	--stop_sig <= stop;

	--State machine Process
	PROCESS (GPIO_1_D5M_PIXCLK, start_i, stop_i)
	BEGIN
		IF rsi_reset_n = '1'THEN
			IF rising_edge(GPIO_1_D5M_PIXCLK) THEN
				CASE STATE IS
					WHEN IDLE =>
						IF start_i = '1' AND NOT(stop_i) = '1' THEN
							STATE <= BUSY;
						END IF;
					WHEN BUSY =>
						IF stop_i = '1' THEN
							STATE <= IDLE;
						END IF;
				END CASE;
			END IF;
		ELSE
			--reset condition
			STATE <= IDLE;
		END IF;
	END PROCESS;

	--DownSampler process
	PROCESS (GPIO_1_D5M_PIXCLK, GPIO_1_D5M_FVAL, GPIO_1_D5M_LVAL, GPIO_1_D5M_D, rsi_reset_n, downsampling_row_counter, valid_row)
	BEGIN
		IF rsi_reset_n = '1' AND STATE = BUSY THEN
			IF rising_edge(GPIO_1_D5M_PIXCLK) THEN
				data_bridge <= GPIO_1_D5M_D;
				IF GPIO_1_D5M_FVAL = '1' AND GPIO_1_D5M_LVAL = '1' THEN
					downsampling_row_counter <= downsampling_row_counter + 1;
					downsampling_col_counter <= downsampling_col_counter + 1; -- TODO maybe do after the next line

					IF downsampling_row_counter = x"9FF" THEN -- divide by 2560
						--valid_row <= NOT(valid_row);
						downsampling_row_counter <= (OTHERS => '0');
					END IF;

					IF downsampling_col_counter = b"11" THEN -- divide by 4
						downsampling_col_counter <= (OTHERS => '0');
					END IF;

					IF (valid_row = '1') AND downsampling_col_counter < b"10" AND downsampling_row_counter <= x"9FE" THEN
						pixel_valid <= '1';
					ELSE
						pixel_valid <= '0';
					END IF;
					--bayer_fifo_push <= push_state AND pixel_valid;
					--bayer_fifo_pop <= NOT(push_state) AND pixel_valid;
				ELSE
					pixel_valid <= '0';
				END IF;
			END IF;
		ELSE
			--reset condition
			pixel_valid <= '0';
			downsampling_row_counter <= (OTHERS => '0');
			downsampling_col_counter <= (OTHERS => '0');
			valid_row <= '1';
			--bayer_fifo_push <= '0';
			--bayer_fifo_pop <= '0';
			--push_state <= '1';
		END IF;
	END PROCESS;
	--Debayering Process
	--WARNING BLACK MAGIC IN THERE, DON'T WASTE YOUR TIME :)
	PROCESS (GPIO_1_D5M_PIXCLK, GPIO_1_D5M_D, pixel_valid)
	BEGIN
		IF rsi_reset_n = '1' AND STATE = BUSY THEN
			IF rising_edge(GPIO_1_D5M_PIXCLK) THEN
				IF usedw_sig = b"1010000000" THEN -- when 640 reached -> pop fifo
					push_state <= '0';
				ELSIF usedw_sig = b"0000000000" THEN -- when 0 reached -> push fifo
					push_state <= '1';
				END IF;

				IF push_state = '0' AND pixel_valid = '1' THEN
					--pops bayer data and combines with reading to push in buffer fifo
					IF usedw_sig(0) = '0' THEN --B is read, G1 pops
						output_color(5 - 1 DOWNTO 0) <= unsigned(data_bridge(12 - 1 DOWNTO 7));
						output_color(10 - 1 DOWNTO 5) <= unsigned(q_sig(12 - 1 DOWNTO 7));
					ELSE --G2 is read, R pops
						output_color(11 - 1 DOWNTO 5) <= resize(output_color(10 - 1 DOWNTO 5), 6) + unsigned(data_bridge(12 - 1 DOWNTO 7));
						output_color(16 - 1 DOWNTO 11) <= unsigned(q_sig(12 - 1 DOWNTO 7));
						color_ready <= '1';
					END IF;
				END IF;
				IF color_ready = '1' THEN
					color_ready <= '0';
				END IF;
			END IF;
		ELSE
			--reset condition
			push_state <= '1';
			color_ready <= '0';
			output_color <= (OTHERS => '0');
		END IF;
	END PROCESS;
	--BUFFER FIFO Process
	PROCESS (GPIO_1_D5M_PIXCLK, color_ready)
	BEGIN
		IF rsi_reset_n = '1' AND STATE = BUSY THEN
			IF rising_edge(GPIO_1_D5M_PIXCLK) THEN
				IF color_ready = '1' THEN
					--color_ready <= '0';
					buffer_write <= '1';
				ELSE
					buffer_write <= '0';
				END IF;
			END IF;
		ELSE
			--reset condition
			buffer_write <= '0';
		END IF;
	END PROCESS;
END comp;