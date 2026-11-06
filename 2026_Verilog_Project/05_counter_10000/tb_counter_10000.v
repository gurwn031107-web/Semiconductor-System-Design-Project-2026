`timescale 1ns / 1ps

module tb_counter_10000 ();

    reg        clk;
    reg        reset;
    reg  btn_R, btn_L, btn_U;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    parameter TEST_DELAY = 25_000_000;  // 25m

    top_counter_10000 dut (
        .clk     (clk),
        .reset   (reset),
        .btn_L   (btn_L),
        .btn_R   (btn_R),
        .btn_UP  (btn_UP),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );
    
    //clock generation 100Mhz
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        {btn_R, btn_L, btn_U} = 3'b000;
        #10;
        reset = 0;

        // 1   STOP
        {btn_R, btn_L, btn_U} = 3'b000;
        #(TEST_DELAY);

        // 2   RUN btn push
        {btn_R, btn_L, btn_U} = 3'b010;
        #10;
        {btn_R, btn_L, btn_U} = 3'b000;
        #(TEST_DELAY);
        {btn_R, btn_L, btn_U} = 3'b010;
        #10;
        {btn_R, btn_L, btn_U} = 3'b000;
        #(TEST_DELAY);

        {btn_R, btn_L, btn_U} = 3'b100;
        #(TEST_DELAY); 
        {btn_R, btn_L, btn_U} = 3'b000;
        #(TEST_DELAY);

       #1000;
        $stop;
    end

endmodule