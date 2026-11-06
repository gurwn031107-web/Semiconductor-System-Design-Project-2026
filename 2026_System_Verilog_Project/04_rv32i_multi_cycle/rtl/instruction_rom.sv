
module instruction_rom (
    input logic [31:0] instr_addr,
    output logic [31:0] instr_code
);

    logic [31:0] instr_rom [0:15];

    initial begin
        instr_rom[0] = 32'h0041_82b3; // add x5, x3, x4
        instr_rom[1] = 32'h0053_0323; // sb x6, 6(x6)
        instr_rom[2] = 32'h0053_1323; // sh x6 6(x6)
        instr_rom[3] = 32'h0053_2323; // sw x6, 6(x6)
        instr_rom[4] = 32'h0023_8413; // addi x8, x7, 2
        instr_rom[5] = 32'h0063_0403; // lb x8, 6(x6)
        instr_rom[6] = 32'h0063_1483; // lh x9, 6(x6)
        instr_rom[7] = 32'h0063_2503; // lw x10, 6(x6)
        instr_rom[8] = 32'h0063_4583; // lbu x11, 6(x6)
        instr_rom[9] = 32'h0063_5603; // LHU x12, 6(x6)
        instr_rom[10] = 32'hfe62_8ce3; // beq x5, x6, -8
        instr_rom[11] = 32'hfe62_9ce3; // bne x5, x6, -8
    end

    assign instr_code = instr_rom[instr_addr[5:2]];


endmodule
