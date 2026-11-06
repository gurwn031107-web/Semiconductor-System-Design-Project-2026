`timescale 1ns / 1ps

module ascii_decoder(
    input clk,
    input reset,
    input [7:0] rx_data,
    input       rx_done,
    input       tx_busy,
    input       tx_done,
    input       tx,
    output  i_run_stop,
    output  i_clear,
    output  i_mode,
    output  i_save_return,
    output  i_sec_up,
    output  i_min_up,
    output  i_hour_up,
    output  i_minus,
    );

    
endmodule
