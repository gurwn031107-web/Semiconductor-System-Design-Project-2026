`timescale 1ns/1ps
module tb_u_type;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst_n = 0;
    logic [31:0] instr_code, instr_addr, daddr, dwdata;
    logic [31:0] drdata = 32'hcafebabe;
    logic dwe;
    logic [2:0] itype;
    rv32i_cpu dut(.*);
    task automatic check_instr(input logic [31:0] insn,
                               input logic [31:0] expected);
        @(negedge clk);
        instr_code = insn;
        #1;
        if (dut.U_DATAPATH.wb_muxout !== expected || !dut.rf_we || dwe)
            $fatal(1, "insn=%h PC=%h result=%h expected=%h", insn, instr_addr,
                   dut.U_DATAPATH.wb_muxout, expected);
        @(posedge clk);
        #1;
        if (insn[11:7] != 0 && dut.U_DATAPATH.U_REG_FILE.ram_file[insn[11:7]] !== expected)
            $fatal(1, "Register write failed");
    endtask
    initial begin
        instr_code = 32'h00000013;
        repeat (2) @(posedge clk);
        @(negedge clk); rst_n = 1;
        // First tested instruction is at PC=4.
        check_instr(32'h12345537, 32'h12345000); // LUI x10
        check_instr(32'h12345597, 32'h12345008); // AUIPC x11, PC=8
        check_instr(32'h80000637, 32'h80000000);
        check_instr(32'hfffff697, 32'hfffff010); // AUIPC PC=16
        check_instr(32'h00000717, 32'h00000014); // AUIPC zero immediate
        check_instr(32'hfffff037, 32'hfffff000); // LUI x0 discarded
        check_instr(32'h00000793, 32'h00000000); // ADDI from x0
        check_instr(32'h00550813, 32'h12345005); // dependent ADDI
        check_instr(32'h00b508b3, 32'h2468a008); // ADD x17,x10,x11
        check_instr(32'h00002903, 32'hcafebabe); // LW writeback regression
        @(negedge clk); instr_code = 32'h00000463; // BEQ x0,x0,+8 at PC=44
        @(posedge clk); #1;
        if (instr_addr !== 32'd52) $fatal(1, "Taken branch failed");
        @(negedge clk); instr_code = 32'h00001463; // BNE x0,x0,+8: not taken
        @(posedge clk); #1;
        if (instr_addr !== 32'd56) $fatal(1, "Not-taken branch failed");
        @(negedge clk); instr_code = 32'hfe000ce3; // BEQ x0,x0,-8
        @(posedge clk); #1;
        if (instr_addr !== 32'd48) $fatal(1, "Backward branch failed");
        $display("PASS: U-type, ADD/ADDI/LW and branch regression");
        $finish;
    end
    initial begin #2000; $fatal(1, "Timeout"); end
endmodule

