
module instruction_rom (
	input		logic [31:0]	instr_addr,
	output	logic	[31:0]	instr_code
);

	logic	[31:0]	instr_rom	[0:127];

	//`ifdef	SIMULATION_TEST
	initial begin
		// R-Type	Simulation
		instr_rom[0]	=	32'h0041_82b3;		//	ADD	x5,	x3,	x4
		instr_rom[1]	=	32'h4040_8333;		//	SUB	x6,	x1,	x4
		instr_rom[2]	=	32'h0023_13B3;		//	SLL	x7,	x6,	x2
		instr_rom[3]	=	32'h0023_2433;		//	SLT	x8,	x6,	x2
		instr_rom[4]	=	32'h0023_34B3;		//	SLTU	x9,	x6,	x2
		instr_rom[5]	=	32'h0023_4533;		//	XOR	x10,	x6,	x2
		instr_rom[6]	=	32'h0023_55B3;		//	SRL	x11,	x6,	x2
		instr_rom[7]	=	32'h4023_5633;		//	SRA	x12,	x6,	x2
		instr_rom[8]	=	32'h0023_66B3;		//	OR	x13,	x6,	x2
		instr_rom[9]	=	32'h0023_7733;		//	AND	x14,	x6,	x2
			//I-Type Simulation
			// SLTI test(-3)
			instr_rom[0]	=	32'h4040_8333;		//	SUB x6, x1, x4

			instr_rom[1]	=	32'h00A0_8513;		//	ADDI x10, x1, 10
			instr_rom[2]	=	32'h00A3_2593;		//	SLTI x11, x6, 10
			instr_rom[3]	=	32'h00A3_3613;		//	SLTIY x12, x6, 10
			instr_rom[4]	=	32'h00A1_C693;		//	XORI x13, x3, 10
			instr_rom[5]	=	32'h00A2_6713;		//	ORI x14, x4, 10
			instr_rom[6]	=	32'h00A0_F793;		//	ANDI x15, x1, 10
			instr_rom[7]	=	32'h0021_1813;		//	SLLI x16, x2, 2
			instr_rom[8]	=	32'h0012_5893;		//	SRLI x17, x4, 1
			instr_rom[9]	=	32'h0023_5913;		//	SRAI x18, x6, 2



		//instr_rom[1]	=	32'h0053_0323;		//	sb	x6,	6(x6)
		//instr_rom[2]	=	32'h0053_1323;		//	sh	x6	6(x6)
		//instr_rom[3]	=	32'h0053_2323;		//	sw	x6,	6(x6)
		//instr_rom[4]	=	32'h0023_8413;		//	addi	x8,	x7,	2
		//instr_rom[5]	=	32'h0063_0403;		//	lb	x8, 6(x6)
		//instr_rom[6]	=	32'h0063_1483;		//	lh	x9, 6(x6)
		//instr_rom[7]	=	32'h0063_2503;		//	lw	x10, 6(x6)
		//instr_rom[8]	=	32'h0063_4583;		//	lbu	x11, 6(x6)
		//instr_rom[9]	=	32'h0063_5603;		//	LHU	x12, 6(x6)
		//instr_rom[10]	=	32'hfe62_8ce3;		//	beq	x5,	x6,	-8
		//instr_rom[11]	=	32'hfe62_9ce3;		//	bne	x5,	x6,	-8
		//instr_rom[12] = 32'h1234_5537;		// lui x10, 0x12345
    //instr_rom[13] = 32'h1234_5597;		// auipc x11, 0x12345
    //instr_rom[14] = 32'h00c0_00ef;		// jal x1, +12 → [17]
    //instr_rom[15] = 32'h0010_0613;		// addi x12, x0, 1
    //instr_rom[16] = 32'h00c0_006f;		// jal x0, +12 → [19]
    //instr_rom[17] = 32'h0070_0693;		// addi x13, x0, 7
    //instr_rom[18] = 32'h0000_8067;		// jalr x0, 0(x1) → [15]
    //instr_rom[19] = 32'h0000_006f;		// jal x0, 0
	end
	//`endif

	initial	begin
		$readmemh("./rtl/rom_code_ex1.mem",instr_rom,0);
	end

	assign instr_code	=	instr_rom[instr_addr[31:2]];


endmodule
