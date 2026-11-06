`timescale 1ns / 1ps

module register_8 (
    input clk,
    input reset,
    input [7:0] d,
    input we,
    output [7:0] q
);

    reg [7:0] q_reg;

    assign q = q_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) q_reg <= 0;
        else begin
            if (we) q_reg <= d;
        end
    end


endmodule

