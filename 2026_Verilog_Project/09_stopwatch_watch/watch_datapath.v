`timescale 1ns / 1ps

module watch_datapath #(

    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH  = 6,
    parameter MIN_WIDTH  = 6,
    parameter HOUR_WIDTH = 5
) (
    input                       clk,
    input                       reset,
    input                       i_tick,
    input                       sec_up,
    input                       min_up,
    input                       hour_up,
    input                       sec_down,
    input                       min_down,
    input                       hour_down,
    output [MSEC_WIDTH - 1 : 0] msec,
    output [ SEC_WIDTH - 1 : 0] sec,
    output [ MIN_WIDTH - 1 : 0] min,
    output [HOUR_WIDTH - 1 : 0] hour
);

    reg [MSEC_WIDTH - 1 : 0] msec_reg;
    reg [ SEC_WIDTH - 1 : 0] sec_reg;
    reg [ MIN_WIDTH - 1 : 0] min_reg;
    reg [HOUR_WIDTH - 1 : 0] hour_reg;

    assign msec = msec_reg;
    assign sec  = sec_reg;
    assign min  = min_reg;
    assign hour = hour_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            msec_reg <= 0;
            sec_reg  <= 0;
            min_reg  <= 0;
            hour_reg <= 0;
        end else begin
            if (sec_up) begin
                if (sec_reg == 59) begin
                    sec_reg <= 0;
                end else begin
                    sec_reg <= sec_reg + 1'b1;
                end
            end else if (min_up) begin
                if (min_reg == 59) begin
                    min_reg <= 0;
                end else begin
                    min_reg <= min_reg + 1'b1;
                end
            end else if (hour_up) begin
                if (hour_reg == 23) begin
                    hour_reg <= 0;
                end else begin
                    hour_reg <= hour_reg + 1'b1;
                end
            end else if (sec_down) begin
                if (sec_reg == 0) begin
                    sec_reg <= 59;
                end else begin
                    sec_reg <= sec_reg - 1'b1;
                end
            end else if (min_down) begin
                if (min_reg == 0) begin
                    min_reg <= 59;
                end else begin
                    min_reg <= min_reg - 1'b1;
                end
            end else if (hour_down) begin
                if (hour_reg == 0) begin
                    hour_reg <= 23;
                end else begin
                    hour_reg <= hour_reg - 1'b1;
                end
            end else if (i_tick) begin
                if (msec_reg == 99) begin
                    msec_reg <= 0;
                    if (sec_reg == 59) begin
                        sec_reg <= 0;
                        if (min_reg == 59) begin
                            min_reg <= 0;
                            if (hour_reg == 23) begin
                                hour_reg <= 0;
                            end else begin
                                hour_reg <= hour_reg + 1'b1;
                            end
                        end else begin
                            min_reg <= min_reg + 1'b1;
                        end
                    end else begin
                        sec_reg <= sec_reg + 1'b1;
                    end
                end else begin
                    msec_reg <= msec_reg + 1'b1;
                end
            end
        end
    end

endmodule
