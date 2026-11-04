
module tb_rv32i ();
    logic clk, rst_n;
    always #5 clk = ~clk;

    rv32i_top dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0);
    end

    initial begin
        clk = 0;
        rst_n = 0;
        #10;
        rst_n = 1;
        // The random R/I test needs several milliseconds for 30,000 trials.
        // This remains only a fallback; tb_rv32i_uvm ends the run when complete.
        #10_000_000;
        $finish;
    end
endmodule
