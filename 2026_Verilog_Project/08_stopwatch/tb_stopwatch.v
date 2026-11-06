`timescale 1ns / 1ps

module tb_stopwatch ();

    reg clk, reset, run_stop, clear, mode;
    wire [6:0] msec;
    wire [5:0] sec, min;
    wire [4:0] hour;

    parameter TICK_DELAY = 1_000_000 * 10;

    stopwatch_datapath DUT (
        .clk     (clk),
        .reset   (reset),
        .run_stop(run_stop),
        .clear   (clear),
        .mode    (mode),
        .msec    (msec),
        .sec     (sec),
        .min     (min),
        .hour    (hour)
    );


    // generator clock 100Mhz
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        run_stop = 0;
        clear = 0;
        mode = 0;
        #10;
        reset = 0;
        #(TICK_DELAY * 5);
        #100;
        $stop;
    end

endmodule
