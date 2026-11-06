`timescale 1ns / 1ps

module dht11_controller (
    input         clk,
    input         reset,
    input         start,
    output [15:0] humidity,
    output [15:0] temperature,
    output        done,
    output        valid,
    inout         dht11_io
);
    wire w_o_tick_10us;

    tick_10us U_TICK_10US (
        .clk        (clk),
        .reset      (reset),
        .o_tick_10us(w_o_tick_10us)
    );

    localparam [2:0]
        IDLE   = 0,
        START  = 1,
        WAIT   = 2,
        SYNC_L = 3,
        SYNC_H = 4,
        DATA   = 5,
        STOP   = 6;

    reg [2:0] c_state, n_state;

    reg io_control;

    reg dht11_io_reg;
    reg dht11_io_next;

    assign dht11_io = (io_control) ? dht11_io_reg : 1'bz;

    reg [$clog2(1900)-1:0] tick_count_reg, tick_count_next;

    reg [$clog2(40)-1:0] bit_count_reg, bit_count_next;

    reg [39:0] data_reg, data_next;

    reg [15:0] humidity_reg, humidity_next;
    reg [15:0] temperature_reg, temperature_next;

    reg valid_reg, valid_next;
    reg dht11_done_reg, dht11_done_next;

    assign humidity    = humidity_reg;
    assign temperature = temperature_reg;
    assign valid       = valid_reg;
    assign done        = dht11_done_reg;

    wire [7:0] checksum;

    assign checksum =
          data_reg[39:32]
        + data_reg[31:24]
        + data_reg[23:16]
        + data_reg[15:8];


    reg dht11_io_d1;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            dht11_io_d1 <= 1'b1;
        end else begin
            dht11_io_d1 <= dht11_io;
        end
    end


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state         <= IDLE;
            dht11_io_reg    <= 1'b1;
            tick_count_reg  <= 0;
            bit_count_reg   <= 0;
            data_reg        <= 40'd0;
            humidity_reg    <= 16'd0;
            temperature_reg <= 16'd0;
            dht11_done_reg  <= 1'b0;
            valid_reg       <= 1'b0;

        end else begin
            c_state         <= n_state;
            dht11_io_reg    <= dht11_io_next;
            tick_count_reg  <= tick_count_next;
            bit_count_reg   <= bit_count_next;
            data_reg        <= data_next;
            humidity_reg    <= humidity_next;
            temperature_reg <= temperature_next;
            dht11_done_reg  <= dht11_done_next;
            valid_reg       <= valid_next;
        end
    end

    always @(*) begin
        n_state          = c_state;
        dht11_io_next    = dht11_io_reg;
        tick_count_next  = tick_count_reg;
        bit_count_next   = bit_count_reg;
        data_next        = data_reg;
        humidity_next    = humidity_reg;
        temperature_next = temperature_reg;
        valid_next       = valid_reg;
        dht11_done_next  = 1'b0;
        io_control       = 1'b1;

        case (c_state)
            IDLE: begin
                dht11_io_next = 1'b1;
                io_control    = 1'b0;
                tick_count_next = 0;
                bit_count_next  = 0;
                if (start) begin
                    data_next = 0;
                    valid_next = 1'b0;
                    n_state = START;
                end
            end

            START: begin
                io_control    = 1'b1;
                dht11_io_next = 1'b0;
                if (w_o_tick_10us) begin
                    if (tick_count_reg == 1900 - 1) begin
                        tick_count_next = 0;
                        n_state = WAIT;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            WAIT: begin
                dht11_io_next = 1'b1;
                io_control = 1'b0;
                if (w_o_tick_10us) begin
                    tick_count_next = tick_count_reg + 1;
                end
                if ((tick_count_reg >= 2) && (!dht11_io)) begin
                    tick_count_next = 0;
                    n_state = SYNC_L;
                end else if (tick_count_reg >= 10) begin
                    tick_count_next = 0;
                    valid_next = 1'b0;
                    n_state = IDLE;
                end
            end
            SYNC_L: begin
                io_control = 1'b0;
                if (w_o_tick_10us) begin
                    tick_count_next = tick_count_reg + 1;
                end
                //LOW -> HIGH
                if (dht11_io) begin
                    tick_count_next = 0;
                    n_state = SYNC_H;
                end  // Timeout
                else if (tick_count_reg >= 12) begin
                    tick_count_next = 0;
                    valid_next = 1'b0;
                    n_state = IDLE;
                end
            end

            SYNC_H: begin
                io_control = 1'b0;
                if (w_o_tick_10us) begin
                    tick_count_next = tick_count_reg + 1;
                end
                if (!dht11_io) begin
                    tick_count_next = 0;
                    bit_count_next = 0;
                    n_state = DATA;
                end else if (tick_count_reg >= 12) begin
                    tick_count_next = 0;
                    valid_next = 1'b0;
                    n_state = IDLE;
                end
            end
            DATA: begin
                io_control = 1'b0;
                if ((dht11_io_d1 == 1'b0) && (dht11_io == 1'b1)) begin
                    tick_count_next = 0;
                end else if (dht11_io == 1'b1) begin
                    if (w_o_tick_10us) begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end else if ((dht11_io_d1 == 1'b1) && (dht11_io == 1'b0)) begin
                    if (tick_count_reg >= 5) begin
                        data_next = {data_reg[38:0], 1'b1};
                    end else begin
                        data_next = {data_reg[38:0], 1'b0};
                    end
                    tick_count_next = 0;
                    if (bit_count_reg == 39) begin
                        bit_count_next = 0;
                        n_state = STOP;
                    end else begin
                        bit_count_next = bit_count_reg + 1;
                    end
                end
            end

            STOP: begin
                io_control = 1'b0;
                if (dht11_io == 1'b1) begin
                    dht11_done_next = 1'b1;
                    if (checksum == data_reg[7:0]) begin
                        valid_next = 1'b1;
                        humidity_next = {data_reg[39:32], data_reg[31:24]};
                        temperature_next = {data_reg[23:16], data_reg[15:8]};
                    end else begin
                        valid_next = 1'b0;
                    end
                    n_state = IDLE;
                end
            end

            default: begin
                n_state = IDLE;
            end
        endcase
    end

endmodule


module tick_10us (
    input  clk,
    input  reset,
    output o_tick_10us
);

    parameter F_COUNT = 100_000_000 / 100_000;

    reg [$clog2(F_COUNT)-1:0] counter_reg;

    reg tick_10us_reg;

    assign o_tick_10us = tick_10us_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg   <= 0;
            tick_10us_reg <= 1'b0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg   <= 0;
                tick_10us_reg <= 1'b1;
            end else begin
                counter_reg   <= counter_reg + 1;
                tick_10us_reg <= 1'b0;
            end
        end
    end

endmodule
