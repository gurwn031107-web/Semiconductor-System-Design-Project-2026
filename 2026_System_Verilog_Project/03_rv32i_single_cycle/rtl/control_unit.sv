
module control_unit
	import	rv32i_pkg::*;
(
	input		logic	[31:0]	instr_code,
	output	logic					rf_we,
	output	logic					alusrc_sel,
	output	logic	[3:0]		alu_control,
	output	logic	[2:0]		rf_srcsel,
	output	logic					dwe,
	output	logic	[2:0]		itype,	//instruction	type	:	funct3
	output	logic					jal,
	output	logic					jalr,
	output	logic					branch
);

	logic	[2:0]	funct3;
	opcode_e	opcode;
    instr_rtype_e instr_rtype;
    instr_btype_e instr_btype;
    instr_itype_e instr_itype;
    instr_iltype_e instr_iltype;
    instr_stype_e instr_stype;
    instr_utype_e instr_utype;
    instr_jtype_e instr_jtype;
    instr_ijtype_e instr_ijtype;

    assign instr_rtype  = instr_rtype_e'(alu_control);
    assign instr_btype  = instr_btype_e'({1'b0, funct3});
    assign instr_itype  = instr_itype_e'(alu_control);
    assign instr_iltype = instr_iltype_e'(funct3);
    assign instr_stype  = instr_stype_e'(funct3);
    assign instr_utype  = instr_utype_e'(instr_code[6:0]);
    assign instr_jtype  = instr_jtype_e'(instr_code[6:0]);
    assign instr_ijtype = instr_ijtype_e'(instr_code[6:0]);

	assign	opcode	=	opcode_e'(instr_code[6:0]);

	assign	funct3	=	instr_code[14:12];



	always_comb	begin
		rf_we				=	1'b0;
		branch			=	1'b0;
		alusrc_sel	=	1'b0;
		alu_control	=	4'b0_000;		//	{funct7[5],	funct3}
		rf_srcsel		=	1'b0;				//	To conrtol for WB	to reg_file,	0:alu_result,	1:drdata
		dwe					=	1'b0;
		jal					=	1'b0;
		jalr				=	1'b0;
		itype				=	3'b010;			//	SW,LW
		case(opcode)
			OP_RTYPE:	begin
				rf_we				=	1'b1;
				branch			=	1'b0;
				alusrc_sel	=	1'b0;
				alu_control	=	{instr_code[30],funct3};
				rf_srcsel		=	3'b000;
				dwe					=	1'b0;
				itype				=	3'b111;	//	SW,	LW
			end
			OP_BTYPE:	begin
				rf_we				=	1'b0;
				alusrc_sel	=	1'b0;
				alu_control	=	{1'b0,funct3};
				rf_srcsel		=	3'b000;
				dwe					=	1'b0;
				branch			=	1'b1;
				itype				=	3'b000;
			end
			OP_STYPE:	begin
				rf_we				=	1'b0;
				alusrc_sel	=	1'b1;
				alu_control	=	32'd0;
				rf_srcsel		=	3'b000;
				dwe					=	1'b1;
				branch			=	1'b0;
				itype				=	funct3;	//	SW,KW
			end
			OP_ITYPE:	begin
				rf_we				=	1'b1;
				alusrc_sel	=	1'b1;
				rf_srcsel		=	3'b000;
				if	(funct3	==	3'b101)
					alu_control	=	{instr_code[30],funct3};
				else
					alu_control	=	{1'b0,funct3};
				dwe					=	1'b0;
				branch			=	1'b0;
				itype				=	3'b111;	//	for	:	data_mem
			end
			OP_ILTYPE:	begin
				rf_we				=	1'b1;
				alusrc_sel	=	1'b1;
				alu_control	=	32'd0;
				rf_srcsel		=	3'b001;
				dwe					=	1'b0;
				branch			=	1'b0;
				itype				=	funct3;	//	SW,KW
			end
			OP_JTYPE: begin
        rf_we = 1'b1;
        rf_srcsel = 3'b100;
        jal = 1'b1;
      end
      OP_JLTYPE: begin
				if(funct3	==	3'b000)	begin
					rf_we = 1'b1;
          rf_srcsel = 3'b100;
          jalr = 1'b1;
				end
      end
      OP_ULTYPE: begin
         rf_we = 1'b1;
         rf_srcsel =	3'b010;
      end
			OP_UATYPE:	begin
				rf_we	=	1'b1;
				rf_srcsel	=	3'b011;
			end

		endcase
	end

endmodule

