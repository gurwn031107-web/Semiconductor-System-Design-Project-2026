`timescale 1ps/1ps

import uvm_pkg::*;

//`include "uvm"

class CParent;
    int a;
    int b;
    int c;

    function new();
        a = 0;
        b = 20;
        c = 30;
    endfunction

    task adder(int x1, int x2);
        c = x1 + x2;
    endtask

endclass

class CChild extends CParent;
    int d;
    int e;

    function new();
      super.new();
        d = 1;
        e = 2;
    endfunction

    task print(int y);
        $display("y = %d", y);
    endtask

endclass

module hello();
    CChild child;

    initial begin
        child = new();
        child.adder(child.a, child.b);
        child.print(child.c);
    end

endmodule
