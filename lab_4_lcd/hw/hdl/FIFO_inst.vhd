FIFO_inst : FIFO PORT MAP (
		clock	 => clock_sig,
		data	 => data_sig,
		rdreq	 => rdreq_sig,
		sclr	 => sclr_sig,
		wrreq	 => wrreq_sig,
		almost_full	 => almost_full_sig,
		empty	 => empty_sig,
		q	 => q_sig
	);