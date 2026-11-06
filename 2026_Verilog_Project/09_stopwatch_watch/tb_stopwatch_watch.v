`timescale 1ns / 1ps

module tb_stopwatch_watch();

    reg clk;
    reg reset;
    reg btn_L;
    reg btn_R;
    reg btn_U;
    reg btn_D;
    reg [1:0] sw;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire [4:0] led;

    parameter TICK_DELAY = 1_000_000 * 10;
    parameter BTN_DELAY  = 20_000;

    top_stopwatch_watch DUT (
        .clk     (clk),
        .reset   (reset),
        .btn_L   (btn_L),
        .btn_R   (btn_R),
        .btn_U   (btn_U),
        .btn_D   (btn_D),
        .sw      (sw),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data),
        .led     (led)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 1'b0;
        reset = 1'b1;
        btn_L = 1'b0;
        btn_R = 1'b0;
        btn_U = 1'b0;
        btn_D = 1'b0;
        sw    = 2'b00;

        #100;
        reset = 1'b0;

        sw = 2'b00;
        #TICK_DELAY;

        btn_L = 1'b1;
        #BTN_DELAY;
        btn_L = 1'b0;
        #BTN_DELAY;
        #(TICK_DELAY * 3);

        sw = 2'b10;
        #(TICK_DELAY * 3);


        btn_R = 1'b1;
        #BTN_DELAY;
        btn_R = 1'b0;
        #BTN_DELAY;
        #(TICK_DELAY * 2);

        btn_U = 1'b1;
        #BTN_DELAY;
        btn_U = 1'b0;
        #BTN_DELAY;
        #(TICK_DELAY * 2);

        btn_L = 1'b1;
        #BTN_DELAY;
        btn_L = 1'b0;
        #BTN_DELAY;
        #(TICK_DELAY * 2);

        btn_D = 1'b1;
        #BTN_DELAY;
        btn_D = 1'b0;
        #BTN_DELAY;
        #(TICK_DELAY * 2);

        btn_R = 1'b1;
        #BTN_DELAY;
        btn_R = 1'b0;
        #BTN_DELAY;
        #(TICK_DELAY * 2);
        btn_D = 1'b1;
        #BTN_DELAY;
        btn_D = 1'b0;
        #BTN_DELAY;
        #(TICK_DELAY * 2);


        sw = 2'b11;
        #(TICK_DELAY * 3);

        sw = 2'b00;
        #(TICK_DELAY * 3);

        $stop;
    end

endmodule
