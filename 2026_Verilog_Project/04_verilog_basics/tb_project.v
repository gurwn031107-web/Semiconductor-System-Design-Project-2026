`timescale 1ns / 1ps


module tb_project ();

    reg clk, a, b;

    //blocking
    initial begin
        a   = 0;
        b   = 1;
        clk = 0;
    end

    always #5 clk = ~clk;

    //    always @(posedge clk) begin
    //        a = b;
    //        b = a;
    //        $display("a =%d, b=%d", a, b);
    //    end

    // non-blocking
    //    always @(posedge clk) begin
    //        a<=b;
    //        b<=a;
    //        $display("a =%d, b=%d", a, b);
    //    end



endmodule
