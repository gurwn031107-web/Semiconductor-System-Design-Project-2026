`timescale 1ns / 1ps

module ascii_sender (
    input        clk,
    input        reset,

    input        i_send,

    input  [3:0] sw,
    input        display_mode,

    input  [6:0] msec,
    input  [5:0] sec,
    input  [5:0] min,
    input  [4:0] hour,

    input  [8:0]  distance,
    input  [15:0] humidity,
    input  [15:0] temperature,
    input         dht_sel_temp,

    input        tx_busy,
    input        tx_done,

    output reg       tx_start,
    output reg [7:0] tx_data
);

    parameter IDLE = 3'd0;
    parameter D3   = 3'd1;
    parameter D2   = 3'd2;
    parameter D1   = 3'd3;
    parameter D0   = 3'd4;
    parameter CR   = 3'd5;
    parameter LF   = 3'd6;

    reg [2:0] c_state;

    reg [3:0] digit_3_reg;
    reg [3:0] digit_2_reg;
    reg [3:0] digit_1_reg;
    reg [3:0] digit_0_reg;

    reg send_wait;

    reg [15:0] sensor_value;


    always @(*) begin
        if (sw[3]) begin
            if (dht_sel_temp) begin
                sensor_value = temperature[15:8];
            end else begin
                sensor_value = humidity[15:8];
            end

        end else if (sw[2]) begin
            sensor_value = distance;

        end else begin
            sensor_value = 16'd0;
        end
    end


    always @(*) begin
        case (c_state)
            D3: tx_data = 8'h30 + digit_3_reg;
            D2: tx_data = 8'h30 + digit_2_reg;
            D1: tx_data = 8'h30 + digit_1_reg;
            D0: tx_data = 8'h30 + digit_0_reg;

            CR: tx_data = 8'h0D;
            LF: tx_data = 8'h0A;

            default: tx_data = 8'h00;
        endcase
    end


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;

            digit_3_reg <= 4'd0;
            digit_2_reg <= 4'd0;
            digit_1_reg <= 4'd0;
            digit_0_reg <= 4'd0;

            send_wait <= 1'b0;
            tx_start  <= 1'b0;

        end else begin

            tx_start <= 1'b0;

            case (c_state)

                IDLE: begin
                    send_wait <= 1'b0;

                    if (i_send) begin

                        // DHT11 / SR04
                        if (sw[3] || sw[2]) begin
                            digit_3_reg <= (sensor_value / 1000) % 10;
                            digit_2_reg <= (sensor_value / 100) % 10;
                            digit_1_reg <= (sensor_value / 10) % 10;
                            digit_0_reg <= sensor_value % 10;
                        end

                        // Hour / Min
                        else if (display_mode) begin
                            digit_3_reg <= (hour / 10) % 10;
                            digit_2_reg <= hour % 10;
                            digit_1_reg <= (min / 10) % 10;
                            digit_0_reg <= min % 10;
                        end

                        // Sec / Msec
                        else begin
                            digit_3_reg <= (sec / 10) % 10;
                            digit_2_reg <= sec % 10;
                            digit_1_reg <= (msec / 10) % 10;
                            digit_0_reg <= msec % 10;
                        end

                        c_state <= D3;
                    end
                end


                D3: begin
                    if (!send_wait && !tx_busy) begin
                        tx_start  <= 1'b1;
                        send_wait <= 1'b1;

                    end else if (send_wait && tx_done) begin
                        send_wait <= 1'b0;
                        c_state   <= D2;
                    end
                end


                D2: begin
                    if (!send_wait && !tx_busy) begin
                        tx_start  <= 1'b1;
                        send_wait <= 1'b1;

                    end else if (send_wait && tx_done) begin
                        send_wait <= 1'b0;
                        c_state   <= D1;
                    end
                end


                D1: begin
                    if (!send_wait && !tx_busy) begin
                        tx_start  <= 1'b1;
                        send_wait <= 1'b1;

                    end else if (send_wait && tx_done) begin
                        send_wait <= 1'b0;
                        c_state   <= D0;
                    end
                end


                D0: begin
                    if (!send_wait && !tx_busy) begin
                        tx_start  <= 1'b1;
                        send_wait <= 1'b1;

                    end else if (send_wait && tx_done) begin
                        send_wait <= 1'b0;
                        c_state   <= CR;
                    end
                end


                CR: begin
                    if (!send_wait && !tx_busy) begin
                        tx_start  <= 1'b1;
                        send_wait <= 1'b1;

                    end else if (send_wait && tx_done) begin
                        send_wait <= 1'b0;
                        c_state   <= LF;
                    end
                end


                LF: begin
                    if (!send_wait && !tx_busy) begin
                        tx_start  <= 1'b1;
                        send_wait <= 1'b1;

                    end else if (send_wait && tx_done) begin
                        send_wait <= 1'b0;
                        c_state   <= IDLE;
                    end
                end


                default: begin
                    c_state   <= IDLE;
                    send_wait <= 1'b0;
                end

            endcase
        end
    end

endmodule