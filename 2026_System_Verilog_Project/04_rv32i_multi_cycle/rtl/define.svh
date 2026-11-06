// R_type
`define ADD 4'b0_000
`define SUB 4'b1_000
`define SLL 4'b0_001
`define SLT 4'b0_010
`define SLTU 4'b0_011
`define XOR 4'b0_100
`define SRL 4'b0_101
`define SRA 4'b1_101
`define OR 4'b0_110
`define AND 4'b0_111


// B_type
`define BEQ 4'b0_000
`define BNE 4'b0_001
`define BLT 4'b0_100
`define BGE 4'b0_101
`define BLTU 4'b0_110
`define BGEU 4'b0_111

//// S_type
//`define SB 3'b000
//`define SH 3'b001
//`define SW 3'b010
//
//// I_type
//`define ADDI 4'b0_000
//`define SLLI 4'b0_001
//`define SLTI 4'b0_010
//`define SLTIU 4'b0_011
//`define XORI 4'b0_100
//`define SRLI 4'b0_101
//`define SRAI 4'b1_101
//`define ORI 4'b0_110
//`define ANDI 4'b0_111
//
//// IL_type
//`define LB 3'b000
//`define LH 3'b001
//`define LW 3'b010
//`define LBU 3'b100
//`define LHU 3'b101
//
//// U_type, J,JL_type
//`define LUI 7'b0110111
//`define AUIPC 7'b0010111
//`define JAL 7'b1101111
//`define JALR 7'b1100111
