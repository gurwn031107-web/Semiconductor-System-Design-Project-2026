`timescale 1ns/1ps

module dedicated_cpu(
    input  logic       clk,
    input  logic       rst_n,
    output logic [7:0] out
);

    logic       rf_srcsel;
    logic [1:0] ra0, ra1, waddr;
    logic       we, out_control, lt10;

    datapath u_datapath (
        .clk         (clk),
        .rst_n       (rst_n),
        .rf_srcsel   (rf_srcsel),
        .ra0         (ra0),
        .ra1         (ra1),
        .waddr       (waddr),
        .we          (we),
        .out_control (out_control),
        .lt10        (lt10),
        .out         (out)
    );

    control_unit u_control_unit (
        .clk         (clk),
        .rst_n       (rst_n),
        .lt10        (lt10),
        .rf_srcsel   (rf_srcsel),
        .ra0         (ra0),
        .ra1         (ra1),
        .waddr       (waddr),
        .we          (we),
        .out_control (out_control)
    );

endmodule


module control_unit(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       lt10,
    output logic       rf_srcsel,
    output logic [1:0] ra0,
    output logic [1:0] ra1,
    output logic [1:0] waddr,
    output logic       we,
    output logic       out_control
);

    typedef enum logic [2:0] {s0, s1, s2, s3, s4, s5, s6} state_e;
    state_e c_state, n_state;

    always_ff @(posedge clk) begin
        if (!rst_n)
            c_state <= s0;
        else
            c_state <= n_state;
    end

    always_comb begin
        n_state = c_state;
        case (c_state)
            s0: n_state = s1;
            s1: n_state = s2;
            s2: n_state = s3;
            s3: n_state = lt10 ? s4 : s6;
            s4: n_state = s5;
            s5: n_state = s3;
            s6: n_state = s6;
            default: n_state = s0;
        endcase
    end

    // 첨부 truth table의 x 항목은 합성 안전성을 위해 0으로 지정
    always_comb begin
        rf_srcsel = 1'b0;
        ra0         = 2'd0;
        ra1         = 2'd0;
        waddr       = 2'd0;
        we          = 1'b0;
        out_control = 1'b0;

        case (c_state)
            s0: begin
                rf_srcsel = 1'b1;
                ra0 = 2'd0; ra1 = 2'd0; waddr = 2'd3; we = 1'b1;
            end
            s1: begin
                rf_srcsel = 1'b1;
                ra0 = 2'd0; ra1 = 2'd0; waddr = 2'd2; we = 1'b1;
            end
            s2: begin
                rf_srcsel = 1'b0;
                waddr = 2'd1; we = 1'b1;
            end
            s3: begin
                ra0 = 2'd3;
            end
            s4: begin
                rf_srcsel = 1'b1;
                ra0 = 2'd3; ra1 = 2'd1; waddr = 2'd3; we = 1'b1;
            end
            s5: begin
                rf_srcsel = 1'b1;
                ra0 = 2'd2; ra1 = 2'd3; waddr = 2'd2; we = 1'b1;
            end
            s6: begin
                ra1 = 2'd2;
                out_control = 1'b1;
            end
            default: ;
        endcase
    end

endmodule


module datapath(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rf_srcsel,
    input  logic [1:0] ra0,
    input  logic [1:0] ra1,
    input  logic [1:0] waddr,
    input  logic       we,
    input  logic       out_control,
    output logic       lt10,
    output logic [7:0] out
);

    logic [7:0] wd, rd0, rd1;
    logic [7:0] alu_result;

    // rf_srcsel=0: 상수 1, rf_srcsel=1: ALU 결과
    assign wd = rf_srcsel ? alu_result : 8'd1;

    reg_file u_reg_file (
        .clk   (clk),
        .rst_n (rst_n),
        .ra0   (ra0),
        .ra1   (ra1),
        .waddr (waddr),
        .we    (we),
        .wd    (wd),
        .rd0   (rd0),
        .rd1   (rd1)
    );

    alu u_alu (
        .a          (rd0),
        .b          (rd1),
        .alu_result (alu_result)
    );

    lt10 u_lt10 (
        .in   (rd0),
        .lt10 (lt10)
    );

    assign out = out_control ? rd1 : 8'hzz;

endmodule


module reg_file(
    input  logic       clk,
    input  logic       rst_n,
    input  logic [1:0] ra0,
    input  logic [1:0] ra1,
    input  logic [1:0] waddr,
    input  logic       we,
    input  logic [7:0] wd,
    output logic [7:0] rd0,
    output logic [7:0] rd1
);

    logic [7:0] registers [0:3];

    assign rd0 = registers[ra0];
    assign rd1 = registers[ra1];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            registers[0] <= 8'd0;
            registers[1] <= 8'd0;
            registers[2] <= 8'd0;
            registers[3] <= 8'd0;
        end else if (we) begin
            registers[waddr] <= wd;
        end
    end

endmodule


module alu(
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] alu_result
);
    assign alu_result = a + b;
endmodule


module lt10(
    input  logic [7:0] in,
    output logic       lt10
);
    assign lt10 = (in < 8'd10);
endmodule
