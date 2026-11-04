
module tb_dedicated_cpu();

    logic       clk = 1'b0;
    logic       rst_n = 1'b0;
    logic [7:0] out;

    always #5 clk = ~clk;

    dedicated_cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .out(out)
    );


    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb_dedicated_cpu);
    end

    initial begin
        repeat (2) @(posedge clk);
        rst_n <= 1'b1;

        wait (out !== 8'hzz);
        #1;

        if (out !== 8'd55)
            $fatal(1, "FAIL: expected out=55, actual out=%0d", out);

        $display("PASS: out=%0d", out);
        #10;
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "FAIL: simulation timeout");
    end

endmodule

