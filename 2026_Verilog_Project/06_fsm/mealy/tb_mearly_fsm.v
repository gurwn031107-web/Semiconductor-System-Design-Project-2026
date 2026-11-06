`timescale 1ns / 1ps

module tb_mealy_fsm();

    reg clk;
    reg reset;
    reg i_data;

    wire o_detect;


    mealy_fsm dut (
        .clk      (clk),
        .reset    (reset),
        .i_data   (i_data),
        .o_detect (o_detect)
    );


    // 100MHz Clock
    always #5 clk = ~clk;


    initial begin
        clk     = 1'b0;
        reset   = 1'b1;
        i_data  = 1'b0;

        #20;
        reset = 1'b0;


        // input Pattern : 00101
        @(negedge clk) i_data = 1'b0;
        @(negedge clk) i_data = 1'b0;
        @(negedge clk) i_data = 1'b1;
        @(negedge clk) i_data = 1'b0;
        @(negedge clk) i_data = 1'b1;

        #20;


        // reset
        reset = 1'b1;
        #20;
        reset = 1'b0;


        // input Pattern : 0101
        @(negedge clk) i_data = 1'b0;
        @(negedge clk) i_data = 1'b1;
        @(negedge clk) i_data = 1'b0;
        @(negedge clk) i_data = 1'b1;

        #20;

        $stop;
    end

endmodule