module instruction_rom (
    input logic [31:0] instr_addr,
    output logic [31:0] instr_code
);
    logic [31:0] instr_rom [0:15];
    initial begin
        for (int i=0; i<16; i++) instr_rom[i]=32'h00000013;
        instr_rom[0]  = 32'h12345537; // 0:  lui x10,0x12345
        instr_rom[1]  = 32'h12345597; // 4:  auipc x11,0x12345
        instr_rom[2]  = 32'h010000ef; // 8:  jal x1,+16 -> 24; x1=12
        instr_rom[3]  = 32'h00100613; // 12: addi x12,x0,1 (after return)
        instr_rom[4]  = 32'h0140006f; // 16: jal x0,+20 -> 36
        instr_rom[6]  = 32'h00700693; // 24: addi x13,x0,7
        instr_rom[7]  = 32'h00008067; // 28: jalr x0,0(x1) -> 12
        instr_rom[9]  = 32'h00d02023; // 36: sw x13,0(x0)
        instr_rom[10] = 32'h00002703; // 40: lw x14,0(x0)
        instr_rom[11] = 32'h00e68463; // 44: beq x13,x14,+8 -> 52
        instr_rom[12] = 32'hfff00793; // 48: addi x15,x0,-1 (must skip)
        instr_rom[13] = 32'h00100793; // 52: addi x15,x0,1
        instr_rom[14] = 32'h0000006f; // 56: jal x0,0 (finish loop)
    end
    assign instr_code=instr_rom[instr_addr[5:2]];
endmodule
