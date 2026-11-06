`timescale 1ns / 1ps

module uart_fifo_loopback (
    input  clk,
    input  reset,
    input  rx,
    output tx
);

    wire       w_baud_tick_x16;
    wire       w_rx_done;
    wire [7:0] w_rx_data;
    wire       w_tx_busy;

    wire [7:0] w_fifo_rx_r_data;
    wire w_fifo_rx_full;
    wire w_fifo_rx_empty;
    wire [7:0] w_fifo_tx_r_data;
    wire w_fifo_tx_full;
    wire w_fifo_tx_empty;
   

    uart_tx U_UART_TX (
        .clk        (clk),
        .reset      (reset),
        .tx_start   (~w_fifo_tx_empty),
        .tx_data    (w_fifo_tx_r_data),
        .i_baud_tick(w_baud_tick_x16),
        .tx_busy    (w_tx_busy),
        .tx_done    (),
        .tx         (tx)
    );

    fifo FIFO_TX (
        .clk  (clk),
        .reset(reset),
        .push (~w_fifo_rx_empty),
        .pop  (~w_tx_busy),
        .w_data(w_fifo_rx_r_data),
        .r_data(w_fifo_tx_r_data),
        .full (w_fifo_tx_full),
        .empty(w_fifo_tx_empty)
    );

    baud_tick_x16 U_BAUD_TICK_x16 (
        .clk        (clk),
        .reset      (reset),
        .o_baud_tick(w_baud_tick_x16)
    );

    uart_rx U_UART_RX (
        .clk        (clk),
        .reset      (reset),
        .i_baud_tick(w_baud_tick_x16),
        .rx         (rx),
        .rx_data    (w_rx_data),
        .rx_done    (w_rx_done)
    );

    fifo FIFO_RX (
        .clk  (clk),
        .reset(reset),
        .push (w_rx_done),
        .pop  (~w_fifo_tx_full),
        .w_data(w_rx_data),
        .r_data(w_fifo_rx_r_data),
        .full (),
        .empty(w_fifo_rx_empty)
    );

endmodule

