`include "define.svh"

`define SIMULATION

module datapath(
    input logic pc_en,
    input logic clk,
    input logic rst_n,
    input logic rf_we,
    input logic alusrc_sel,
    input logic [3:0] alu_control,
    input logic [2:0] rf_srcsel,
    input logic branch,
    input logic jal,
    input logic jalr,
    input logic [31:0] instr_code,
    input logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output logic [31:0] daddr,
    output logic [31:0] dwdata
);

    logic [31:0] alu_result, rf_rd1, rf_rd2;
    logic [31:0] imm_extend, alusrc_muxout, wb_muxout, pc_4, pc_imm;
    logic b_taken;

    // Register File 주소: rs1/rs2는 읽기, rd는 결과 기록 대상입니다.
    logic [4:0] rs1_addr, rs2_addr, rd_addr;
    assign rs1_addr = instr_code[19:15];
    assign rs2_addr = instr_code[24:20];
    assign rd_addr = instr_code[11:7];

    logic [31:0] dec_rs1, dec_rs2, dec_imm;
    logic [31:0] exe_alu, exe_rs2, mem_rdata;

    assign daddr = exe_alu;
    assign dwdata = exe_rs2;

    reg_file U_REG_FILE(
        .clk(clk),
        .rst_n(rst_n),
        .ra1(rs1_addr),
        .ra2(rs2_addr),
        .wa(rd_addr),
        .wd(wb_muxout),
        .we(rf_we),
        .rd1(rf_rd1),
        .rd2(rf_rd2)
    );

    mux_5x1 U_WB_MUX(
        .sel(rf_srcsel),
        .in0(alu_result),
        .in1(mem_rdata),
        .in2(dec_imm),
        .in3(pc_imm),
        .in4(pc_4),
        .mux_out(wb_muxout)
    );

    imm_extend U_IMM_EXTEND(
        .instr_code(instr_code),
        .imm_extend(imm_extend)
    );

    mux_2x1 U_ALUSRC_MUX(
        .sel(alusrc_sel),
        .in0(dec_rs2),
        .in1(dec_imm),
        .mux_out(alusrc_muxout)
    );

    alu U_ALU(
        .rs1(dec_rs1),
        .rs2(alusrc_muxout),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .b_taken(b_taken)
    );

    program_counter U_PC(
        .pc_en(pc_en),
        .clk(clk),
        .rst_n(rst_n),
        .b_taken(b_taken),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .imm_extend(dec_imm),
        .pc(instr_addr),
        .rs1(dec_rs1),
        .pc_4(pc_4),
        .pc_imm(pc_imm)
    );



    // 단계 사이의 저장 레지스터: 매 클럭 저장하며 별도 enable은 없습니다.
    // dec_*: DECODE 결과, exe_*: EXECUTE 결과, mem_rdata: RAM 읽기 결과

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            dec_rs1 <= 0;
            dec_rs2 <= 0;
            dec_imm <= 0;
            exe_alu <= 0;
            exe_rs2 <= 0;
            mem_rdata <= 0;
        end else begin
            dec_rs1 <= rf_rd1;
            dec_rs2 <= rf_rd2;
            dec_imm <= imm_extend;
            exe_alu <= alu_result;
            exe_rs2 <= dec_rs2;
            mem_rdata <= drdata;
        end
    end

endmodule

module mux_5x1(
    input logic [2:0] sel,
    input logic [31:0] in0,
    input logic [31:0] in1,
    input logic [31:0] in2,
    input logic [31:0] in3,
    input logic [31:0] in4,
    output logic [31:0] mux_out
);

    always_comb begin
        mux_out = in0;
        case(sel)
            3'b000: mux_out = in0;
            3'b001: mux_out = in1;
            3'b010: mux_out = in2;
            3'b011: mux_out = in3;
            3'b100: mux_out = in4;
        endcase
    end

endmodule

module mux_2x1(
    input logic sel,
    input logic [31:0] in0,
    input logic [31:0] in1,
    output logic [31:0] mux_out
);

    assign mux_out = (sel) ? in1:in0;

endmodule

module reg_file(
    input logic clk,
    input logic rst_n,
    input logic [4:0] ra1,
    input logic [4:0] ra2,
    input logic [4:0] wa,
    input logic [31:0] wd,
    input logic we,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);

    logic [31:0] ram_file [1:31];


    always_ff @(posedge clk) begin
        if(!rst_n) begin
        `ifdef SIMULATION
            for(int i = 1; i<32; i++)
                ram_file[i] <= i;
        `else
            for(int i = 1; i<32; i++)
                ram_file[i] <= 0;
        `endif
        end
        else
            if(we && (wa != 5'd0))
                ram_file[wa] <= wd;
    end

    assign rd1 = ( ra1 != 0) ? ram_file[ra1] :32'd0;
    assign rd2 = ( ra2 != 0) ? ram_file[ra2] :32'd0;

endmodule

module alu(
    input logic [31:0] rs1,
    input logic [31:0] rs2,
    input logic [3:0] alu_control,
    output logic [31:0] alu_result,
    output logic b_taken
);

    always_comb begin
        alu_result = 32'h0000_0000;
        case(alu_control)
            // {funct7[5], funct3}
            `ADD : alu_result = rs1 + rs2; // add
            `SUB : alu_result = rs1 - rs2; // sub
            `XOR : alu_result = rs1 ^ rs2; // xor
            `OR : alu_result = rs1 | rs2; // or
            `AND : alu_result = rs1 & rs2; // and
            `SLL : alu_result = rs1 << rs2[4:0]; // SLL
            `SRL : alu_result = rs1 >> rs2[4:0]; // SRL
            `SRA : alu_result = $signed(rs1) >>> rs2[4:0]; // SRA
            `SLT : alu_result = ($signed(rs1) < $signed(rs2))
                                      ? 32'd1 :32'd0; // SLT
      `SLTU : alu_result = (rs1 < rs2)
                                      ? 32'd1 :32'd0; // SLTU
        endcase
    end

    always_comb begin
        b_taken = 1'b0;
        case(alu_control)
            //BEQ
            `BEQ: begin
                if($signed(rs1) == $signed(rs2)) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            //BNE
            `BNE: begin
                if($signed(rs1) != $signed(rs2)) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            //BLT
            `BLT: begin
                if($signed(rs1) < $signed(rs2)) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            //BGE
            `BGE: begin
                if($signed(rs1) >= $signed(rs2)) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            //BLTU
            `BLTU: begin
                if(rs1 < rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            //BGEU
            `BGEU: begin
                if(rs1 >= rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end

        endcase
    end


endmodule

// imm extender
module imm_extend
    import rv32i_pkg::*;
(
    input logic [31:0] instr_code,
    output logic [31:0] imm_extend
);

    opcode_e opcode;
    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

    assign opcode = opcode_e'(instr_code[6:0]);

    // immediate는 형식마다 비트 배치가 다릅니다.
    // B/J 형식의 최하위 비트는 주소 계산을 위해 0을 붙입니다.
    assign imm_i = {{20{instr_code[31]}}, instr_code[31:20]};
    assign imm_s = {{20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]};
    assign imm_b = {{19{instr_code[31]}}, instr_code[31], instr_code[7],
                    instr_code[30:25], instr_code[11:8], 1'b0};
    assign imm_u = {instr_code[31:12], 12'b0};
    assign imm_j = {{11{instr_code[31]}}, instr_code[31], instr_code[19:12],
                    instr_code[20], instr_code[30:21], 1'b0};

    always_comb begin
        case (opcode)
            OP_ITYPE, OP_ILTYPE, OP_JLTYPE: imm_extend = imm_i;
            OP_STYPE: imm_extend = imm_s;
            OP_BTYPE: imm_extend = imm_b;
            OP_ULTYPE, OP_UATYPE: imm_extend = imm_u;
            OP_JTYPE: imm_extend = imm_j;
            default: imm_extend = 32'd0;
        endcase
    end

endmodule

module program_counter(
    input logic pc_en,
    input logic clk,
    input logic rst_n,
    input logic b_taken,
    input logic branch,
    input logic jal,
    input logic jalr,
    input logic [31:0] imm_extend,
    input logic [31:0] rs1,
    output logic [31:0] pc,
    output logic [31:0] pc_4,
    output logic [31:0] pc_imm // pc_imm
);

    logic [31:0] register_pc;
    logic [31:0] pc_next;
    logic [31:0] pc_base;
    logic pc_srcsel;

    assign pc = register_pc;
    assign pc_srcsel = (b_taken & branch)|jal|jalr;
    assign pc_4 = pc + 4;
    // pc_base는 일반 분기에서 PC, JALR에서 rs1입니다.
    assign pc_imm = pc_base + imm_extend;

    logic [31:0] exe_pc_next;

    // FETCH에서 이전 에지에 저장한 다음 PC를 사용합니다.
    // 둘 다 0으로 리셋해야 첫 FETCH가 주소 0부터 시작합니다.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            register_pc <= 32'd0;
            exe_pc_next <= 32'd0;
        end else begin
            exe_pc_next <= pc_next;
            if (pc_en)
                register_pc <= exe_pc_next;
        end
    end

    mux_2x1 U_PC_RS1_MUX(
        .sel(jalr),
        .in0(pc),
        .in1(rs1),
        .mux_out(pc_base)
    );

    mux_2x1 U_PC_IMM_MUX(
        .sel(pc_srcsel),
        .in0(pc_4),
        .in1(jalr ? {pc_imm[31:1], 1'b0} : pc_imm),
        .mux_out(pc_next)
    );

endmodule

