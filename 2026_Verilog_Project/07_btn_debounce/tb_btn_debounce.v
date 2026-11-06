`timescale 1ns / 1ps

module tb_btn_debounce();

    reg clk;
    reg reset;
    reg i_btn;

    wire o_btn;

    btn_debounce dut(
        .clk(clk),
        .reset(reset),
        .i_btn(i_btn),
        .o_btn(o_btn)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        i_btn = 1'b0;

        #20
        reset = 1'b0;

        #2000;
        i_btn = 1'b1;

        #10000;
        i_btn = 1'b0;

        #10000;

        #5000;

        $stop;
    end

endmodule
