module control_unit
    import rv32i_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic [31:0] instr_code,
    output logic pc_en,
    output logic rf_we,
    output logic alusrc_sel,
    output logic [3:0] alu_control,
    output logic [2:0] rf_srcsel,
    output logic dwe,
    output logic [2:0] itype,
    output logic jal,
    output logic jalr,
    output logic branch
);
    typedef enum logic [2:0] {
        FETCH,
        DECODE,
        EXECUTE,
        MEM,
        WB
    } state_e;
    state_e c_state, n_state;
    opcode_e opcode;
    // 명령어 필드: 원본 비트 위치는 여기서 한 번만 분리합니다.
    logic [6:0] funct7;
    logic [2:0] funct3;

    // Register File에 기록할 데이터 선택 (DataPath WB MUX와 동일)
    localparam logic [2:0] WB_ALU = 3'd0;
    localparam logic [2:0] WB_MEM = 3'd1;
    localparam logic [2:0] WB_IMM = 3'd2;
    localparam logic [2:0] WB_PCIMM = 3'd3;
    localparam logic [2:0] WB_PC4 = 3'd4;

    assign opcode = opcode_e'(instr_code[6:0]);
    assign funct7 = instr_code[31:25];
    assign funct3 = instr_code[14:12];

    // 1. 클럭에 맞춰 현재 상태 저장
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            c_state <= FETCH;
        end else begin
            c_state <= n_state;
        end
    end

    // 2. 명령어 종류에 따른 다음 상태
    always_comb begin
        n_state = c_state;
        case (c_state)
            FETCH: begin
                n_state = DECODE;
            end
            DECODE: begin
                n_state = EXECUTE;
            end
            EXECUTE: begin
                case (opcode)
                    OP_RTYPE, OP_ITYPE, OP_BTYPE,
                    OP_ULTYPE, OP_UATYPE, OP_JTYPE, OP_JLTYPE: begin
                        n_state = FETCH;
                    end
                    OP_STYPE, OP_ILTYPE: begin
                        n_state = MEM;
                    end
                    default: begin
                        n_state = FETCH;
                    end
                endcase
            end
            MEM: begin
                // 현재 data_mem은 조합 읽기이므로 ready 대기 없이 진행합니다.
                case (opcode)
                    OP_STYPE: begin
                        n_state = FETCH;
                    end
                    OP_ILTYPE: begin
                        n_state = WB;
                    end
                    default: begin
                        n_state = FETCH;
                    end
                endcase
            end
            WB: begin
                n_state = FETCH;
            end
            default: begin
                n_state = FETCH;
            end
        endcase
    end

    // 3. 현재 상태와 명령어에 따른 출력 제어
    always_comb begin
        pc_en       = 1'b0;
        rf_we       = 1'b0;
        dwe         = 1'b0;
        branch      = 1'b0;
        jal         = 1'b0;
        jalr        = 1'b0;
        alusrc_sel  = 1'b0;
        alu_control = 4'b0000;
        rf_srcsel   = WB_ALU;
        itype       = 3'b010;

        case (c_state)
            FETCH: begin
                pc_en = 1'b1;
            end
            DECODE: begin
                // DataPath가 rs1, rs2, immediate를 저장합니다.
            end
            EXECUTE: begin
                case (opcode)
                    OP_RTYPE: begin
                        rf_we = 1'b1;
                        alu_control = {funct7[5], funct3};
                    end
                    OP_ITYPE: begin
                        rf_we = 1'b1;
                        alusrc_sel = 1'b1;
                        if (funct3 == 3'b101) begin
                            alu_control = {funct7[5], funct3};
                        end else begin
                            alu_control = {1'b0, funct3};
                        end
                    end
                    OP_BTYPE: begin
                        branch = 1'b1;
                        alu_control = {1'b0, funct3};
                    end
                    OP_STYPE, OP_ILTYPE: begin
                        alusrc_sel = 1'b1;
                        alu_control = 4'b0000;
                    end
                    OP_ULTYPE: begin
                        rf_we = 1'b1;
                        rf_srcsel = WB_IMM;
                    end
                    OP_UATYPE: begin
                        rf_we = 1'b1;
                        rf_srcsel = WB_PCIMM;
                    end
                    OP_JTYPE: begin
                        rf_we = 1'b1;
                        jal = 1'b1;
                        rf_srcsel = WB_PC4;
                    end
                    OP_JLTYPE: begin
                        if (funct3 == 3'b000) begin
                            rf_we = 1'b1;
                            jalr = 1'b1;
                            rf_srcsel = WB_PC4;
                        end
                    end
                    default: begin end
                endcase
            end
            MEM: begin
                // exe_alu가 매 클럭 갱신되므로 주소 계산을 유지합니다.
                alusrc_sel = 1'b1;
                alu_control = 4'b0000;
                itype = funct3;
                if (opcode == OP_STYPE) begin
                    dwe = 1'b1;
                end
                // load: 조합 RAM 출력을 에지에서 mem_rdata에 저장합니다.
            end
            WB: begin
                if (opcode == OP_ILTYPE) begin
                    rf_we = 1'b1;
                    rf_srcsel = WB_MEM;
                end
            end
            default: begin end
        endcase

        if (!rst_n) begin
            pc_en = 1'b0;
            rf_we = 1'b0;
            dwe = 1'b0;
        end
    end
endmodule
