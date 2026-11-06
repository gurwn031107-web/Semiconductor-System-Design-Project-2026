`timescale 1ns / 1ps

module tb_sr04_controller();

    reg clk;
    reg reset;
    reg start;
    reg echo;

    wire trigger;
    wire done;
    wire [8:0] distance;


    sr04_controller dut (
        .clk     (clk),
        .reset   (reset),
        .start   (start),
        .echo    (echo),
        .trigger (trigger),
        .done    (done),
        .distance(distance)
    );


    // 100MHz clock
    always #5 clk = ~clk;


    initial begin
        clk   = 0;
        reset = 1;
        start = 0;
        echo  = 0;

        // reset
        #10;
        reset = 0;


        @(negedge clk);
        start = 1;
        #20;
        start = 0;

        wait(trigger == 1);
        wait(trigger == 0);

        #100_000;

        //580us
        echo = 1;
        #580_000;
        echo = 0;

        // 측정 완료
        wait(done == 1);

        #(12_000);
        $stop;
    end

endmodule