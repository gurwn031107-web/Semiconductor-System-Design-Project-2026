`timescale 1ns / 1ps
// top module
module adder_fnd(
    input  [7:0] a,
    input  [7:0] b,
    input        btn_L,
    input        btn_R,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output       c
);

    wire [7:0] s;

    fnd_controller U_FND_CNTL(
        .fnd_in  (s),
        .digit_sel({btn_L,btn_R}), //concatanation msb : btn_L, lsb : btn_R
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

    adder U_ADDER ( // 8bit adder
        .a  (a),
        .b  (b),
        .s  (s),
        .c  (c)
    );

endmodule


module adder(
    input [7:0] a,
    input [7:0] b,
    output [7:0] s,
    output c
);
    wire c1;

    full_adder_4bit FA_4bit_1(
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(1'b0),
        .s(s[3:0]),
        .c(c1)
    );
    
    full_adder_4bit FA_4bit_2(
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(c1),
        .s(s[7:4]),
        .c(c)
        
    );

endmodule

module full_adder_4bit(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] s,
    output c
);

    wire c1;    
    wire c2;
    wire c3;

    full_adder FA1 (
        .a(a[0]),
        .b(b[0]),
        .cin(cin),
        .s(s[0]),
        .c(c1)
    );

    full_adder FA2 (
        .a(a[1]),
        .b(b[1]),
        .cin(c1),
        .s(s[1]),
        .c(c2)
    );

    full_adder FA3 (
        .a(a[2]),
        .b(b[2]),
        .cin(c2),
        .s(s[2]),
        .c(c3)
    );

    full_adder FA4 (
        .a(a[3]),
        .b(b[3]),
        .cin(c3),
        .s(s[3]),
        .c(c)
    );


endmodule

module full_adder(
    input a,
    input b,
    input cin,
    output s,
    output c
);

    wire s1;
    wire c1;
    wire c2;
    
    assign c = c1 | c2;

    half_adder HA2(
        .a(s1),
        .b(cin),
        .s(s),
        .c(c2)
    );


    half_adder HA1(
        .a(a),
        .b(b),
        .s(s1),
        .c(c1)
    );
    

endmodule


module half_adder (
    input  a,
    input  b,
    output s,
    output c
);

    //assign s = a ^ b;
    //assign c = a & b;

    xor(s, a, b);  //( output, input0, input1, input...)
    and(c, a, b);  // and gate ( output, input0, input1, input...)
    

endmodule
