`timescale 1ns / 1ps


module fsm_moore_led01 (
    input            clk,
    input            reset,
    input      [2:0] sw,
    output reg [2:0] led
);

    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;

    //state register
    reg [2:0] c_state;
    reg [2:0] n_state;

    //state register

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= S0;
        end else begin
            c_state <= n_state;
        end
    end

    // next state Combinational logic

    always @(*) begin
        n_state = c_state;
        case ({c_state, sw})      
            {S0, 3'b001} : n_state = S1;
            {S0, 3'b100} : n_state = S4;
            {S1, 3'b010} : n_state = S2;
            {S2, 3'b011} : n_state = S3;
            {S3, 3'b100} : n_state = S4;
            {S4, 3'b001} : n_state = S1;
            {S4, 3'b111} : n_state = S0;
            //default = c_state = n_state;
        endcase
    end

    //output Combinational logic

    always @(*) begin
        case (c_state)
            S0:      led = 3'b000;
            S1:      led = 3'b001;
            S2:      led = 3'b010;
            S3:      led = 3'b011;
            S4:      led = 3'b100;
            default: led = 3'b000;
        endcase
    end

endmodule