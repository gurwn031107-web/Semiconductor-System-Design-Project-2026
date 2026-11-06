`timescale 1ns/1ps
module tb_rom;
    logic clk=0, rst_n=0;
    always #5 clk=~clk;
    rv32i_top dut(.*);
    logic [31:0] expected_pc [0:13] = '{0,4,8,24,28,12,16,36,40,44,52,56,56,56};
    initial begin
        repeat(2) @(posedge clk);
        @(negedge clk); rst_n=1;
        for(int i=0;i<14;i++) begin
            if(dut.instr_addr !== expected_pc[i]) $fatal(1,"PC step %0d: %h",i,dut.instr_addr);
            @(posedge clk); #1; @(negedge clk);
        end
        if(dut.U_RV32I_CPU.U_DATAPATH.U_REG_FILE.ram_file[10] !== 32'h12345000) $fatal(1,"LUI");
        if(dut.U_RV32I_CPU.U_DATAPATH.U_REG_FILE.ram_file[11] !== 32'h12345004) $fatal(1,"AUIPC");
        if(dut.U_RV32I_CPU.U_DATAPATH.U_REG_FILE.ram_file[1] !== 12) $fatal(1,"Link");
        if(dut.U_RV32I_CPU.U_DATAPATH.U_REG_FILE.ram_file[12] !== 1) $fatal(1,"Return");
        if(dut.U_RV32I_CPU.U_DATAPATH.U_REG_FILE.ram_file[14] !== 7) $fatal(1,"Load");
        if(dut.U_DATA_MEM.dmem[0] !== 7) $fatal(1,"Store");
        if(dut.U_RV32I_CPU.U_DATAPATH.U_REG_FILE.ram_file[15] !== 1) $fatal(1,"Branch");
        $display("PASS: ROM + CPU + data memory, U-type, call/return, branch");
        $finish;
    end
    initial begin #3000; $fatal(1,"Timeout"); end
endmodule
