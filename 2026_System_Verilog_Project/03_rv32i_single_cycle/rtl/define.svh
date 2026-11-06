//	R_type
`define	ADD		4'b0_000
`define	SUB		4'b1_000
`define	SLL		4'b0_001
`define	SLT		4'b0_010
`define	SLTU	4'b0_011
`define	XOR		4'b0_100
`define	SRL		4'b0_101
`define	SRA		4'b1_101
`define	OR		4'b0_110
`define	AND		4'b0_111


// B_type
`define	BEQ		4'b0_000
`define	BNE		4'b0_001
`define	BLT		4'b0_100
`define	BGE		4'b0_101
`define	BLTU	4'b0_110
`define	BGEU	4'b0_111

// Named waveform types, based on the existing macros.
typedef enum logic [3:0] {
    R_ADD=`ADD, R_SUB=`SUB, R_SLL=`SLL, R_SLT=`SLT,
    R_SLTU=`SLTU, R_XOR=`XOR, R_SRL=`SRL, R_SRA=`SRA,
    R_OR=`OR, R_AND=`AND
} instr_rtype_e;
typedef enum logic [3:0] {
    B_BEQ=`BEQ, B_BNE=`BNE, B_BLT=`BLT,
    B_BGE=`BGE, B_BLTU=`BLTU, B_BGEU=`BGEU
} instr_btype_e;

// I-type arithmetic: same encoding as alu_control.
`define ADDI  4'b0_000
`define SLLI  4'b0_001
`define SLTI  4'b0_010
`define SLTIU 4'b0_011
`define XORI  4'b0_100
`define SRLI  4'b0_101
`define SRAI  4'b1_101
`define ORI   4'b0_110
`define ANDI  4'b0_111

typedef enum logic [3:0] {
    I_ADDI=`ADDI, I_SLLI=`SLLI, I_SLTI=`SLTI, I_SLTIU=`SLTIU,
    I_XORI=`XORI, I_SRLI=`SRLI, I_SRAI=`SRAI, I_ORI=`ORI, I_ANDI=`ANDI
} instr_itype_e;

// Load and store: funct3.
`define LB  3'b000
`define LH  3'b001
`define LW  3'b010
`define LBU 3'b100
`define LHU 3'b101
`define SB  3'b000
`define SH  3'b001
`define SW  3'b010

typedef enum logic [2:0] {
    IL_LB=`LB, IL_LH=`LH, IL_LW=`LW, IL_LBU=`LBU, IL_LHU=`LHU
} instr_iltype_e;
typedef enum logic [2:0] {
    S_SB=`SB, S_SH=`SH, S_SW=`SW
} instr_stype_e;

// U-type and jump names are distinguished by opcode, not funct3.
`define LUI   7'b0110111
`define AUIPC 7'b0010111
`define JAL   7'b1101111
`define JALR  7'b1100111

typedef enum logic [6:0] {
    U_LUI=`LUI, U_AUIPC=`AUIPC
} instr_utype_e;
typedef enum logic [6:0] {
    J_JAL=`JAL
} instr_jtype_e;
// JALR uses the I-type immediate format, but has its own opcode.
typedef enum logic [6:0] {
    IJ_JALR=`JALR
} instr_ijtype_e;


