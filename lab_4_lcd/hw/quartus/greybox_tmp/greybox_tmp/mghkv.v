//scfifo ADD_RAM_OUTPUT_REGISTER="OFF" ALMOST_FULL_VALUE=224 CBX_SINGLE_OUTPUT_FILE="ON" INTENDED_DEVICE_FAMILY=""Cyclone V"" LPM_HINT="RAM_BLOCK_TYPE=M10K" LPM_NUMWORDS=256 LPM_SHOWAHEAD="OFF" LPM_TYPE="scfifo" LPM_WIDTH=16 LPM_WIDTHU=8 OVERFLOW_CHECKING="ON" UNDERFLOW_CHECKING="ON" USE_EAB="OFF" aclr almost_full clock data empty q rdreq wrreq
//VERSION_BEGIN 18.1 cbx_mgl 2018:09:12:13:10:36:SJ cbx_stratixii 2018:09:12:13:04:24:SJ cbx_util_mgl 2018:09:12:13:04:24:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2018  Intel Corporation. All rights reserved.
//  Your use of Intel Corporation's design tools, logic functions 
//  and other software and tools, and its AMPP partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Intel Program License 
//  Subscription Agreement, the Intel Quartus Prime License Agreement,
//  the Intel FPGA IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Intel and sold by Intel or its authorized distributors.  Please
//  refer to the applicable agreement for further details.



//synthesis_resources = scfifo 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mghkv
	( 
	aclr,
	almost_full,
	clock,
	data,
	empty,
	q,
	rdreq,
	wrreq) /* synthesis synthesis_clearbox=1 */;
	input   aclr;
	output   almost_full;
	input   clock;
	input   [15:0]  data;
	output   empty;
	output   [15:0]  q;
	input   rdreq;
	input   wrreq;

	wire  wire_mgl_prim1_almost_full;
	wire  wire_mgl_prim1_empty;
	wire  [15:0]   wire_mgl_prim1_q;

	scfifo   mgl_prim1
	( 
	.aclr(aclr),
	.almost_full(wire_mgl_prim1_almost_full),
	.clock(clock),
	.data(data),
	.empty(wire_mgl_prim1_empty),
	.q(wire_mgl_prim1_q),
	.rdreq(rdreq),
	.wrreq(wrreq));
	defparam
		mgl_prim1.add_ram_output_register = "OFF",
		mgl_prim1.almost_full_value = 224,
		mgl_prim1.intended_device_family = ""Cyclone V"",
		mgl_prim1.lpm_numwords = 256,
		mgl_prim1.lpm_showahead = "OFF",
		mgl_prim1.lpm_type = "scfifo",
		mgl_prim1.lpm_width = 16,
		mgl_prim1.lpm_widthu = 8,
		mgl_prim1.overflow_checking = "ON",
		mgl_prim1.underflow_checking = "ON",
		mgl_prim1.use_eab = "OFF",
		mgl_prim1.lpm_hint = "RAM_BLOCK_TYPE=M10K";
	assign
		almost_full = wire_mgl_prim1_almost_full,
		empty = wire_mgl_prim1_empty,
		q = wire_mgl_prim1_q;
endmodule //mghkv
//VALID FILE
