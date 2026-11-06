`timescale 1ns / 1ps

module top_counter_10000 (
    input        clk,
    input        reset,
    input        btn_L,  // run_stop
    input        btn_R,  // clear
    input        btn_U, // mode
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire [13:0] w_counter;
    wire w_reset;
    wire w_run_stop, w_clear, w_mode;
    wire w_bd_runstop, w_bd_clear, w_bd_mode;

    assign w_reset = reset | w_clear;

    // This have to be a btn debounce logic

`timescale 1ns / 1ps

    btn_debounce U_BD_RUNSTOP (
        .clk(clk),
        .reset(reset),
        .i_btn(btn_L),
        .o_btn(w_bd_runstop)
    );

    btn_debounce U_BD_CLEAR (
        .clk(clk),
        .reset(reset),
        .i_btn(btn_R),
        .o_btn(w_bd_clear)
    );

    btn_debounce U_BD_MODE (
        .clk(clk),
        .reset(reset),
        .i_btn(btn_U),
        .o_btn(w_bd_mode)
    );

    control_unit U_CONTROL_UNIT (
        .clk       (clk),
        .reset     (reset),
        .i_run_stop(w_bd_runstop),
        .i_clear   (w_bd_clear),
        .i_mode    (w_bd_mode),
        .o_run_stop(w_run_stop),
        .o_clear   (w_clear),
        .o_mode    (w_mode)
    );

    datapath_10000 U_DATAPATH_10000 (
        .clk     (clk),
        .reset   (w_reset),
        .mode    (w_mode),
        .run_stop(w_run_stop),
        .counter (w_counter)
    );

    fnd_controller U_FND_CTRL (
        .clk     (clk),
        .reset   (w_reset),
        .fnd_in  (w_counter),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

endmodule

module datapath_10000 (
    input         clk,
    input         reset,
    input         mode,
    input         run_stop,
    output [13:0] counter
);

    wire w_tick;


    counter_10000 U_COUNTER_10000 (
        .clk     (clk),
        .reset   (reset),
        .mode    (mode),
        .run_stop(run_stop),
        .i_tick  (w_tick),
        .counter (counter)
    );

    tick_gen U_TICK_GEN (
        .clk(clk),
        .reset(reset),
        .run_stop(run_stop),
        .tick(w_tick)
    );

endmodule

module counter_10000 (
    input         clk,
    input         reset,
    input         mode,
    input         run_stop,
    input         i_tick,
    output [13:0] counter
);
    reg [$clog2(10000) - 1:0] tick_counter_reg;

    assign counter = tick_counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            tick_counter_reg <= 0;
        end else begin
            if (run_stop & i_tick) begin
                if (!mode) begin  // 0: mode up count
                    tick_counter_reg <= tick_counter_reg + 1;
                    if (tick_counter_reg == (10000 - 1)) tick_counter_reg <= 0;
                end else begin
                    tick_counter_reg <= tick_counter_reg - 1;
                    if (tick_counter_reg == 0) tick_counter_reg <= (10000 - 1);
                end
            end
        end
    end

endmodule

module tick_gen (
    input  clk,
    input  reset,
    input  run_stop,
    output tick
);

    reg [$clog2(1_000_000) - 1:0] counter_reg;
    reg tick_reg;

    assign tick = tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            tick_reg <= 0;
        end else begin
            if (run_stop) begin
                counter_reg <= counter_reg + 1;

                if (counter_reg == (1_000_000 - 1)) begin
                    counter_reg <= 0;
                    tick_reg <= 1'b1;
                end else begin
                    tick_reg <= 1'b0;
                end
            end
        end
    end

endmodule
