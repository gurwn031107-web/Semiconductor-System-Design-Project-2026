`timescale 1ns / 1ps

module stopwatch_datapath #(

    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH  = 6,
    parameter MIN_WIDTH  = 6,
    parameter HOUR_WIDTH = 5

) (
    input                       clk,
    input                       reset,
    input                       run_stop,
    input                       clear,
    input                       mode,
    input                       save,
    input                       return_count,

    output [MSEC_WIDTH-1:0] msec,
    output [SEC_WIDTH-1:0]  sec,
    output [MIN_WIDTH-1:0]  min,
    output [HOUR_WIDTH-1:0] hour
);

    wire w_tick_100hz;
    wire w_tick_sec;
    wire w_tick_min;
    wire w_tick_hour;

    wire w_reset;

    assign w_reset = reset | clear;


    time_counter #(
        .BIT_WIDTH(HOUR_WIDTH),
        .TIMES(24)
    ) U_HOUR_COUNTER (
        .clk         (clk),
        .reset       (w_reset),
        .i_tick      (w_tick_hour),
        .mode        (mode),
        .run_stop    (run_stop),
        .clear       (clear),
        .save        (save),
        .return_count(return_count),
        .time_count  (hour),
        .o_tick      ()
    );


    time_counter #(
        .BIT_WIDTH(MIN_WIDTH),
        .TIMES(60)
    ) U_MIN_COUNTER (
        .clk         (clk),
        .reset       (w_reset),
        .i_tick      (w_tick_min),
        .mode        (mode),
        .run_stop    (run_stop),
        .clear       (clear),
        .save        (save),
        .return_count(return_count),
        .time_count  (min),
        .o_tick      (w_tick_hour)
    );


    time_counter #(
        .BIT_WIDTH(SEC_WIDTH),
        .TIMES(60)
    ) U_SEC_COUNTER (
        .clk         (clk),
        .reset       (w_reset),
        .i_tick      (w_tick_sec),
        .mode        (mode),
        .run_stop    (run_stop),
        .clear       (clear),
        .save        (save),
        .return_count(return_count),
        .time_count  (sec),
        .o_tick      (w_tick_min)
    );


    time_counter #(
        .BIT_WIDTH(MSEC_WIDTH),
        .TIMES(100)
    ) U_MSEC_COUNTER (
        .clk         (clk),
        .reset       (w_reset),
        .i_tick      (w_tick_100hz),
        .mode        (mode),
        .run_stop    (run_stop),
        .clear       (clear),
        .save        (save),
        .return_count(return_count),
        .time_count  (msec),
        .o_tick      (w_tick_sec)
    );


    tick_gen_100hz U_TICK_GEN_100HZ (
        .clk   (clk),
        .reset (reset),
        .o_tick(w_tick_100hz)
    );

endmodule

module time_counter #(
    parameter BIT_WIDTH = 7,
    parameter TIMES     = 100
) (
    input                  clk,
    input                  reset,
    input                  i_tick,
    input                  mode,
    input                  run_stop,
    input                  clear,
    input                  save,
    input                  return_count,

    output [BIT_WIDTH-1:0] time_count,
    output reg             o_tick
);

    reg [$clog2(TIMES)-1:0] counter_reg;
    reg [$clog2(TIMES)-1:0] save_reg;

    assign time_count = counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick      <= 1'b0;
            save_reg    <= 0;
        end else begin
            o_tick <= 1'b0;

            if (return_count) begin
                counter_reg <= save_reg;

            end else if (save) begin
                save_reg <= counter_reg;

            end else if (i_tick && run_stop) begin
                if (!mode) begin
                    if (counter_reg == TIMES - 1) begin
                        counter_reg <= 0;
                        o_tick      <= 1'b1;
                    end else begin
                        counter_reg <= counter_reg + 1'b1;
                    end
                end else begin
                    if (counter_reg == 0) begin
                        counter_reg <= TIMES - 1;
                        o_tick      <= 1'b1;
                    end else begin
                        counter_reg <= counter_reg - 1'b1;
                    end
                end
            end
        end
    end

endmodule