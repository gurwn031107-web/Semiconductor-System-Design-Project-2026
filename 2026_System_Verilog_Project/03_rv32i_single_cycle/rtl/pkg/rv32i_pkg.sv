package	rv32i_pkg;
    `include "./rtl/define.svh"
	typedef	enum	logic	[6:0]	{
		OP_RTYPE	=	7'b011_0011,
		OP_STYPE	=	7'b010_0011,
		OP_ITYPE	=	7'b001_0011,
		OP_ILTYPE	=	7'b000_0011,
		OP_BTYPE	=	7'b110_0011,
		OP_ULTYPE = 7'b011_0111,
		OP_UATYPE = 7'b001_0111,
    OP_JTYPE  = 7'b110_1111,
    OP_JLTYPE = 7'b110_0111
	}	opcode_e;

endpackage


