`timescale 1ns / 1ps

module disp_strobe();
    reg [7:0] a;
    reg [7:0] b;

    initial begin
            a = 8'h34;
            b = 8'h34;
        #10 b <= a + 1;
        $display("$display-1 : time=%0t a=%h b=%h", $time, a, b);
        $strobe("$strobe-1 : time=%0t a=%h b=%h", $time, a, b);
        #5
        $display("$display-2 : time=%0t a=%h b=%h", $time, a, b);
        $strobe("$strobe-2 : time=%0t a=%h b=%h", $time, a, b); 
    end

endmodule
