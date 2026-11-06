`timescale 1ns / 1ps

module tb_ram ();

    reg clk;
    reg [5:0] addr;
    reg [7:0] w_data;
    reg wr;
    wire [7:0] r_data;


    ram_ip DUT (
        .clk   (clk),
        .addr  (addr),
        .w_data(w_data),
        .wr    (wr),
        .r_data(r_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        addr = 0;
        w_data = 0;
        wr = 0;
        #10;

        addr = 10;
        w_data = 8'h0a;
        wr = 1;
        #10;

        addr = 11;
        w_data = 8'h0b;
        wr = 1;
        #10;

        addr = 31;
        w_data = 8'h0c;
        wr = 1;
        #10;

        addr = 32;
        w_data = 8'h0d;
        wr = 1;
        #10;

        addr = 10;
        wr   = 0;
        #10; 

        addr = 11;
        wr = 0;
        #10;

        addr = 31;
        wr = 0;
        #10;

        addr = 32;
        wr = 0;
        #10; 
        $stop;
    end

endmodule
