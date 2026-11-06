`timescale 1ns / 1ps

module moore_fsm (
    input clk,
    input reset,
    input i_data,
    output reg o_detect
);

    parameter S0 = 3'b000;  // 검출된 값 없음
    parameter S1 = 3'b001;  // 0
    parameter S2 = 3'b010;  // 01
    parameter S3 = 3'b011;  // 010
    parameter S4 = 3'b100;  // 0101 검출

    reg [2:0] c_state;
    reg [2:0] n_state;


    // 현재 상태 저장
    always @(posedge clk or posedge reset) begin
        if (reset) c_state <= S0;
        else c_state <= n_state;
    end


    // 다음 상태 결정
    always @(*) begin
        case (c_state)

            S0: begin
                if (i_data == 1'b0) n_state = S1;
                else n_state = S0;
            end

            S1: begin
                if (i_data == 1'b0) n_state = S1;
                else n_state = S2;
            end

            S2: begin
                if (i_data == 1'b0) n_state = S3;
                else n_state = S0;
            end

            S3: begin
                if (i_data == 1'b0) n_state = S1;
                else n_state = S4;
            end

            S4: begin
                if (i_data == 1'b0) n_state = S1;
                else n_state = S0;
            end

            default: begin
                n_state = S0;
            end

        endcase
    end


    // 출력 결정
    always @(*) begin
        if (c_state == S4) o_detect = 1'b1;
        else o_detect = 1'b0;
    end

endmodule
