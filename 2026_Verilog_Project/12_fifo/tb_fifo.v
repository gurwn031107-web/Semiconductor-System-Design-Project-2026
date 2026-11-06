`timescale 1ns / 1ps

module tb_fifo ();

    parameter WIDTH = 2;

    reg                clk;
    reg                reset;
    reg                push;
    reg                pop;
    reg  [        7:0] w_data;
    // for random
    reg  [        7:0] compare_buffer[0:(2**WIDTH)-1];
    reg  [WIDTH - 1:0] push_cnt;
    reg  [WIDTH - 1:0] pop_cnt;

    wire [        7:0] r_data;
    wire               full;
    wire               empty;

    integer pass_count = 0, fail_count = 0;
    integer i;

    fifo #(
        .WIDTH(2)
    ) dut (
        .clk   (clk),
        .reset (reset),
        .push  (push),
        .pop   (pop),
        .w_data(w_data),
        .r_data(r_data),
        .full  (full),
        .empty (empty)
    );


    // 100MHz
    always #5 clk = ~clk;


    initial begin

        clk    = 0;
        reset  = 1;
        push   = 0;
        pop    = 0;
        w_data = 0;

        #10;
        reset  = 0;

        //  Push Only : 5 times

        push   = 1;
        pop    = 0;

        w_data = 8'h0A;  // A
        #10;

        w_data = 8'h0B;  // B
        #10;

        w_data = 8'h0C;  // C
        #10;

        w_data = 8'h0D;  // D
        #10;

        w_data = 8'h0E;  // E : Full 상태에서 Push
        #10;


        // 1 cycle delay
        push = 0;
        #10;

        // 2. Pop Only : 5 times
        @(negedge clk);
        push = 0;
        pop  = 1;

        #10;
        #10;
        #10;
        #10;
        #10;  // Empty 상태에서 Pop


        // 1 cycle delay
        pop = 0;
        #10;

        // 3-1. Push 1 time

        push   = 1;
        pop    = 0;
        w_data = 8'h0A;
        #10;

        // 3-2. Push + Pop : 8 times

        push = 1;
        pop = 1;

        w_data = 8'h0B;
        #10;

        w_data = 8'h0C;
        #10;

        w_data = 8'h0D;
        #10;

        w_data = 8'h0E;
        #10;

        w_data = 8'h0F;
        #10;

        w_data = 8'h10;
        #10;

        w_data = 8'h11;
        #10;

        w_data = 8'h12;
        #10;

        // 3-3. Pop 1 time

        push = 0;
        pop  = 1;
        #10;


        $display("%t : RANDOM test start", $time);
        push_cnt = 0;
        pop_cnt  = 0;
        //@(negedge clk);

        // empty state
        for (i = 0; i < 256; i = i + 1) begin
            @(posedge clk);
            #1;

            push = $random % 2;
            pop = $random % 2;
            w_data = $random % 256;
            $display("%t : push = %d, pop = %d, w_data = %d", $time, push, pop,
                     w_data);
            @(negedge clk);
            if (!full & push) begin
                compare_buffer[push_cnt] = w_data;
                $display("%t : compare_buffer = %d, push = %d", $time,
                         compare_buffer[push_cnt], push);
                push_cnt = push_cnt + 1'b1;
            end

            if (full & push) begin
                $display("%t : FULL!! push = %d, full = %d", $time, push, full);

            end

            if (!empty & pop) begin
                if (compare_buffer[pop_cnt] == r_data) begin
                    $display(
                        "%t : PASS!! compare_data = %d, r_data = %d, pop = %d, empty = %d",
                        $time, compare_buffer[pop_cnt], r_data, pop, empty);
                    pass_count = pass_count + 1;
                end else begin
                    $display(
                        "%t : FAIL!! compare_data = %d, r_data = %d, pop = %d, empty = %d",
                        $time, compare_buffer[pop_cnt], r_data, pop, empty);
                    fail_count = fail_count + 1;
                end
                pop_cnt = pop_cnt + 1'b1;
            end

            if (empty & pop) begin
                $display("%t : EMPTY!! pop = %d, empty = %d", $time, pop,
                         empty);

            end

        end

        $display("%t : pass_count = %d, fail_count = %d", $time, pass_count,
                 fail_count);

        #100;

        $stop;

    end

endmodule
