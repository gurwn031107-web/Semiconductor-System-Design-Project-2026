`timescale 1ns / 1ps

module top_dht11 (
    input         clk,
    input         reset,
    input         start,
    output [15:0] humidity,
    output [15:0] temperature,
    output        done,
    output        valid,
    inout         dht11_io

);

    wire w_start;

    btn_debounce U_BTN_DEBOUNCE (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_U),
        .o_btn(w_start)
    );

    dht11_controller U_DHT11_CONTROLLER (
        .clk        (clk),
        .reset      (reset),
        .start      (w_start),
        .humidity   (humidity),
        .temperature(temperature),
        .done       (done),
        .valid      (valid),
        .dht11_io   (dht11_io)
    );

endmodule

