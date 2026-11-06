`timescale 1ns / 1ps

module tb_test();

    integer inta, intb, intc, intd;

    initial begin
        inta = -12 / 4;
        intb = -'d12/4;
        intc = -'sd12/4;
        intd = -4'sd12/4;
        $display("inta = %d, intb = %d, intc = %d, intd = %d", inta, intb, intc, intd);
        #1;
        $finish;
    end
endmodule
