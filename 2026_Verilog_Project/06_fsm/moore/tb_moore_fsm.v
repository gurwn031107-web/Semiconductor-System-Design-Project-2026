`timescale 1ns / 1ps

module tb_moore_fsm ();

    reg  clk;
    reg  reset;
    reg  i_data;

    wire o_detect;


    moore_fsm dut (
        .clk     (clk),
        .reset   (reset),
        .i_data  (i_data),
        .o_detect(o_detect)
    );


    // 100MHz Clock
    always #5 clk = ~clk;


    initial begin
        clk    = 1'b0;
        reset  = 1'b1;
        i_data = 1'b0;

        // 초기 Reset
        #20;
        reset = 1'b0;


        // 입력 패턴 : 00101
        @(negedge clk) i_data = 1'b0;

        @(negedge clk) i_data = 1'b0;

        @(negedge clk) i_data = 1'b1;

        @(negedge clk) i_data = 1'b0;

        @(negedge clk) i_data = 1'b1;


        // S4 상태와 o_detect 확인
        @(negedge clk);
        i_data = 1'b0;

        #10;


        // 두 번째 시뮬레이션을 위한 Reset
        reset  = 1'b1;
        i_data = 1'b0;

        #20;
        reset = 1'b0;


        // 입력 패턴 : 0101
        @(negedge clk) i_data = 1'b0;

        @(negedge clk) i_data = 1'b1;

        @(negedge clk) i_data = 1'b0;

        @(negedge clk) i_data = 1'b1;


        // S4 상태와 o_detect 확인
        @(negedge clk) i_data = 1'b0;

        #20;

        $stop;
    end

endmodule
