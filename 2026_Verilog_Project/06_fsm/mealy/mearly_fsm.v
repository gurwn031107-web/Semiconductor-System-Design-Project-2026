`timescale 1ns / 1ps

module mealy_fsm (
    input clk,
    input reset,
    input i_data,
    output reg o_detect
);

    parameter S0 = 2'b00;
    parameter S1 = 2'b01;
    parameter S2 = 2'b10;
    parameter S3 = 2'b11;

    reg [1:0] c_state;
    reg [1:0] n_state;

    always @(posedge clk, posedge reset) begin
        if (reset) c_state <= 0;
        else c_state <= n_state;
    end

    always @(*) begin
        n_state  = S0;
        o_detect = 1'b0;

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
                if (i_data == 1'b0) begin
                    n_state = S1;
                end else begin
                    n_state  = S0;
                    o_detect = 1'b1;
                end
            end

            default: begin
                n_state  = S0;
                o_detect = 1'b0;
            end

        endcase
    end

endmodule
