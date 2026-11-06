`timescale 1ns / 1ps

module tb_Adder();
    
    reg [7:0] a, b;  // 4bit reg    
    wire [7:0] s;    // 4bit wire
    wire c;
    integer i, j;    // integer type 32bit

   
    full_adder_8bit dut(
        .a(a),
        .b(b),
        .s(s),
        .c(c)
    );

    initial begin
        a = 8'b00000000;  // b는 2진수
        b = 8'b00000000;
        #5;

        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i;
                b = j;
                #5;
            end
        end
        //$stop;   // simulation pausing
        $finish;   // simulation ending
    end

endmodule