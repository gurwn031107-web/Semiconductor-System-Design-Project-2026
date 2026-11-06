`timescale 1ns/1ps
module tb_jump;
    logic clk=0, rst_n=0;
    always #5 clk=~clk;
    logic [31:0] instr_code=32'h13, instr_addr, daddr, dwdata;
    logic [31:0] drdata=0;
    logic dwe;
    logic [2:0] itype;
    rv32i_cpu dut(.*);
    function automatic [31:0] j(input integer offset, input logic [4:0] rd);
        logic [20:0] imm;
        imm=offset;
        return {imm[20],imm[10:1],imm[11],imm[19:12],rd,7'b1101111};
    endfunction
    function automatic [31:0] i(input integer imm, input logic [4:0] rs1,
                                input logic [4:0] rd, input logic [6:0] op);
        return {12'(imm),rs1,3'b000,rd,op};
    endfunction
    task automatic step(input logic [31:0] insn, input logic [31:0] next_pc,
                        input logic [31:0] result, input bit write_reg);
        instr_code=insn;
        #1;
        if(dwe || dut.rf_we !== write_reg) $fatal(1,"Control failed insn=%h",insn);
        @(posedge clk); #1;
        if(instr_addr !== next_pc) $fatal(1,"PC insn=%h actual=%h expected=%h",insn,instr_addr,next_pc);
        if(write_reg && insn[11:7]!=0 && dut.U_DATAPATH.U_REG_FILE.ram_file[insn[11:7]] !== result)
            $fatal(1,"Link/write result failed insn=%h",insn);
        @(negedge clk);
    endtask
    initial begin
        repeat(2) @(posedge clk);
        @(negedge clk); rst_n=1;
        step(j(16,1),16,4,1);                    // call
        step(i(0,1,0,7'b1100111),4,0,1);         // return via x1
        step(j(-4,5),0,8,1);                    // backward JAL
        step(i(65,0,6,7'b0010011),4,65,1);
        step(i(0,6,6,7'b1100111),64,8,1);        // rd=rs1, clear bit 0
        step(i(-4,6,7,7'b1100111),4,68,1);       // signed offset; old x6=8
        step(j(8,0),12,0,1);                    // jump without link
        step(i(0,0,8,7'b0010011),16,0,1);        // x0 still zero
        step(j(1048572,9),1048588,20,1);         // J immediate field boundaries
        step(j(-1048576,10),12,1048592,1);
        step(32'h000010e7,16,0,0);              // invalid JALR funct3 ignored
        $display("PASS: JAL/JALR call/return, signed offsets, rd=rs1, x0, bit0, immediate boundaries");
        $finish;
    end
    initial begin #2000; $fatal(1,"Timeout"); end
endmodule
