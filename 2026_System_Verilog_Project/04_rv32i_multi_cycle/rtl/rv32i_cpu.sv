
module rv32i_top(
    input clk,
    input rst_n
);

    logic [31:0] instr_code;
    logic [31:0] instr_addr;
    logic [31:0] daddr;
    logic [31:0] dwdata;
    logic [31:0] drdata;
    logic dwe;
    logic [2:0] itype;

    instruction_rom U_INSTR_ROM(
        .instr_addr(instr_addr),
        .instr_code(instr_code)
    );

    rv32i_cpu U_RV32I_CPU(
        .clk(clk),
        .rst_n(rst_n),
        .instr_code(instr_code),
        .drdata(drdata),
        .instr_addr(instr_addr),
        .daddr(daddr),
        .dwdata(dwdata),
        .dwe(dwe),
        .itype(itype)
    );

    data_mem U_DATA_MEM(
        .clk(clk),
        .dwe(dwe),
        .itype(itype),
        .daddr(daddr),
        .dwdata(dwdata),
        .drdata(drdata)
    );
endmodule

module rv32i_cpu(
    input logic clk,
    input logic rst_n,
    input logic [31:0] instr_code,
    input logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output logic [31:0] daddr,
    output logic [31:0] dwdata,
    output logic dwe,
    output logic [2:0] itype
);

    logic pc_en;

    logic rf_we;
    logic [3:0] alu_control;
    logic alusrc_sel;
    logic [2:0] rf_srcsel;
    logic branch;

    logic jal;
    logic jalr;

    control_unit U_CONTROL_UNIT(
        .clk(clk),
        .rst_n(rst_n),
        .instr_code(instr_code),
        .pc_en(pc_en),
        .rf_we(rf_we),
        .alusrc_sel(alusrc_sel),
        .alu_control(alu_control),
        .rf_srcsel(rf_srcsel),
        .dwe(dwe),
        .itype(itype),
        .jal(jal),
        .jalr(jalr),
        .branch(branch)
    );

    datapath U_DATAPATH(
        .clk(clk),
        .rst_n(rst_n),
        .pc_en(pc_en),
        .rf_we(rf_we),
        .alusrc_sel(alusrc_sel),
        .alu_control(alu_control),
        .rf_srcsel(rf_srcsel),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .instr_code(instr_code),
        .drdata(drdata),
        .instr_addr(instr_addr),
        .daddr(daddr),
        .dwdata(dwdata)
    );

endmodule
