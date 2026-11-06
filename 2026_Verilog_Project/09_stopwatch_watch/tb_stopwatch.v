`timescale 1ns / 1ps

module tb_stopwatch;

    reg clk;
    reg reset;
    reg i_run_stop;
    reg i_clear;
    reg i_mode;
    reg i_save_return;

    wire run_stop;
    wire clear;
    wire mode;
    wire save;
    wire return_count;

    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

    stopwatch_control_unit U_CONTROL (
        .clk          (clk),
        .reset        (reset),
        .i_run_stop   (i_run_stop),
        .i_clear      (i_clear),
        .i_mode       (i_mode),
        .i_save_return(i_save_return),
        .o_run_stop   (run_stop),
        .o_clear      (clear),
        .o_mode       (mode),
        .o_save       (save),
        .o_return     (return_count)
    );

    stopwatch_datapath U_DATAPATH (
        .clk         (clk),
        .reset       (reset),
        .run_stop    (run_stop),
        .clear       (clear),
        .mode        (mode),
        .save        (save),
        .return_count(return_count),
        .msec        (msec),
        .sec         (sec),
        .min         (min),
        .hour        (hour)
    );

    always #5 clk = ~clk;

    initial begin
        clk           = 0;
        reset         = 1;
        i_run_stop    = 0;
        i_clear       = 0;
        i_mode        = 0;
        i_save_return = 0;

        #20;
        reset = 0;
        #20;


        i_run_stop = 1;
        #10;
        i_run_stop = 0;
        #20;

        #50_000_000;

        i_run_stop = 1;
        #10;
        i_run_stop = 0;
        #50_000_000;


        i_run_stop = 1;
        #10;
        i_run_stop = 0;
        #20;

        #1_100_000_000;

        i_save_return = 1;
        #10;
        i_save_return = 0;
        #300_000_000;


        i_run_stop = 1;
        #10;
        i_run_stop = 0;
        #30;

        i_save_return = 1;
        #10;
        i_save_return = 0;
        #100_000_000;


        i_mode = 1;
        #10;
        i_mode = 0;
        #30;

        i_run_stop = 1;
        #10;
        i_run_stop = 0;
        #100_000_000;


        i_run_stop = 1;
        #10;
        i_run_stop = 0;
        #30;


        i_clear = 1;
        #10;
        i_clear = 0;
        #100;

        $finish;
    end

endmodule
