`timescale 1ns / 1ps

module top_uart_sensor (
    input clk,
    input reset,

    input btn_L,
    input btn_R,
    input btn_U,
    input btn_D,

    input [3:0] sw,

    input  rx,
    output tx,

    input  sr04_echo,
    output sr04_trig,
    inout  dht11_io,

    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [4:0] led
);

    // Button debounce
    wire w_btn_L;
    wire w_btn_R;
    wire w_btn_U;
    wire w_btn_D;

    // UART RX / TX
    wire [7:0] w_uart_rx_data;
    wire       w_uart_rx_done;

    wire       w_uart_tx_start;
    wire [7:0] w_uart_tx_data;
    wire       w_uart_tx_busy;
    wire       w_uart_tx_done;

    // UART RX FIFO
    wire [7:0] w_fifo_data;
    wire       w_fifo_valid;

    // ASCII Decoder
    wire [1:0] w_uart_mode_sel;
    wire       w_uart_mode_valid;

    wire w_uart_sw_run;
    wire w_uart_sw_stop;
    wire w_uart_sw_clear;
    wire w_uart_sw_mode;

    wire w_uart_wc_H;
    wire w_uart_wc_M;
    wire w_uart_wc_S;
    wire w_uart_wc_up;
    wire w_uart_wc_down;

    wire w_uart_dht_start;
    wire w_uart_dht_sel_temp;

    wire w_uart_sr04_start;

    // Mode register
    reg  [2:0] r_mode_sel;
    reg  [2:0] r_sw_d;

    wire       w_sw_changed;
    wire [2:0] w_uart_mode_onehot;
    wire [3:0] w_mode;

    // Control Unit
    wire w_run_stop;
    wire w_clear;
    wire w_mode_cnt;
    wire w_save;
    wire w_return;

    wire w_watch_sec_up;
    wire w_watch_min_up;
    wire w_watch_hour_up;

    wire w_watch_sec_down;
    wire w_watch_min_down;
    wire w_watch_hour_down;

    wire w_sr04_start;

    wire w_dht_start;
    wire w_dht_sel_temp;

    // Stopwatch
    wire [6:0] w_stopwatch_msec;
    wire [5:0] w_stopwatch_sec;
    wire [5:0] w_stopwatch_min;
    wire [4:0] w_stopwatch_hour;

    // Watch
    wire       w_watch_tick;

    wire [6:0] w_watch_msec;
    wire [5:0] w_watch_sec;
    wire [5:0] w_watch_min;
    wire [4:0] w_watch_hour;

    // DHT11
    wire [15:0] w_dht_humidity;
    wire [15:0] w_dht_temperature;
    wire        w_dht_done;
    wire        w_dht_valid;

    // SR04
    wire [8:0] w_sr04_distance;
    wire       w_sr04_done;

    // Stopwatch / Watch MUX
    wire [6:0] w_selected_msec;
    wire [5:0] w_selected_sec;
    wire [5:0] w_selected_min;
    wire [4:0] w_selected_hour;

    // ASCII Sender start
    wire w_ascii_send_req;
    reg  w_ascii_send;

    // Sensor value latch
    reg [15:0] r_dht_humidity;
    reg [15:0] r_dht_temperature;
    reg [ 8:0] r_sr04_distance;

    // Sensor request shaping
    reg  r_dht_busy;
    reg  r_sr04_busy;

    wire w_dht_start_level;
    wire w_sr04_start_level;


    // Button debounce
    btn_debounce U_BD_L (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    btn_debounce U_BD_R (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );

    btn_debounce U_BD_U (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_U),
        .o_btn(w_btn_U)
    );

    btn_debounce U_BD_D (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_D),
        .o_btn(w_btn_D)
    );


    // UART Controller
    uart_controller U_UART_CONTROLLER (
        .clk     (clk),
        .reset   (reset),

        .tx_start(w_uart_tx_start),
        .tx_data (w_uart_tx_data),

        .rx      (rx),
        .rx_data (w_uart_rx_data),
        .rx_done (w_uart_rx_done),

        .tx_busy (w_uart_tx_busy),
        .tx_done (w_uart_tx_done),
        .tx      (tx)
    );


    // UART RX FIFO
    uart_rx_fifo #(
        .ADDR_WIDTH(4)
    ) U_UART_RX_FIFO (
        .clk    (clk),
        .reset  (reset),

        .i_write(w_uart_rx_done),
        .i_data (w_uart_rx_data),

        .o_valid(w_fifo_valid),
        .o_data (w_fifo_data)
    );


    // ASCII Decoder
    ascii_decoder U_ASCII_DECODER (
        .clk        (clk),
        .reset      (reset),

        .i_valid    (w_fifo_valid),
        .i_data     (w_fifo_data),
        .i_run_state(w_run_stop),

        .o_mode_sel  (w_uart_mode_sel),
        .o_mode_valid(w_uart_mode_valid),

        .o_sw_run  (w_uart_sw_run),
        .o_sw_stop (w_uart_sw_stop),
        .o_sw_clear(w_uart_sw_clear),
        .o_sw_mode (w_uart_sw_mode),

        .o_wc_H   (w_uart_wc_H),
        .o_wc_M   (w_uart_wc_M),
        .o_wc_S   (w_uart_wc_S),
        .o_wc_up  (w_uart_wc_up),
        .o_wc_down(w_uart_wc_down),

        .o_dht_start   (w_uart_dht_start),
        .o_dht_sel_temp(w_uart_dht_sel_temp),

        .o_sr04_start(w_uart_sr04_start)
    );


    // Mode register (sw change takes priority over UART command)
    assign w_sw_changed = (sw[3:1] != r_sw_d);

    assign w_uart_mode_onehot = (w_uart_mode_sel == 2'd3) ? 3'b100 :  // DHT11
                                (w_uart_mode_sel == 2'd2) ? 3'b010 :  // SR04
                                (w_uart_mode_sel == 2'd1) ? 3'b001 :  // Watch
                                                            3'b000;   // Stopwatch

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_sw_d     <= 3'b000;
            r_mode_sel <= 3'b000;
        end else begin
            r_sw_d <= sw[3:1];

            if (w_sw_changed) begin
                r_mode_sel <= sw[3:1];
            end else if (w_uart_mode_valid) begin
                r_mode_sel <= w_uart_mode_onehot;
            end
        end
    end

    // sw[0] is display mode select, not mode -> pass through
    assign w_mode = {r_mode_sel, sw[0]};


    // Control Unit
    control_unit U_CONTROL_UNIT (
        .clk  (clk),
        .reset(reset),

        .sw(w_mode),

        .i_btn_L(w_btn_L),
        .i_btn_R(w_btn_R),
        .i_btn_U(w_btn_U),
        .i_btn_D(w_btn_D),

        .i_uart_run  (w_uart_sw_run),
        .i_uart_stop (w_uart_sw_stop),
        .i_uart_clear(w_uart_sw_clear),
        .i_uart_mode (w_uart_sw_mode),

        .i_uart_sec_up (w_uart_wc_S),
        .i_uart_min_up (w_uart_wc_M),
        .i_uart_hour_up(w_uart_wc_H),

        .i_uart_up   (w_uart_wc_up),
        .i_uart_down (w_uart_wc_down),

        .i_uart_sr04_start(w_uart_sr04_start),

        .i_uart_dht_start   (w_uart_dht_start),
        .i_uart_dht_sel_temp(w_uart_dht_sel_temp),

        .o_run_stop(w_run_stop),
        .o_clear   (w_clear),
        .o_mode    (w_mode_cnt),
        .o_save    (w_save),
        .o_return  (w_return),

        .o_sec_up (w_watch_sec_up),
        .o_min_up (w_watch_min_up),
        .o_hour_up(w_watch_hour_up),

        .o_sec_down (w_watch_sec_down),
        .o_min_down (w_watch_min_down),
        .o_hour_down(w_watch_hour_down),

        .o_sr04_start(w_sr04_start),

        .o_dht_start   (w_dht_start),
        .o_dht_sel_temp(w_dht_sel_temp)
    );


    // DHT11 request shaping (pulse -> level)
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_dht_busy <= 1'b0;
        end else if (w_dht_done) begin
            r_dht_busy <= 1'b0;
        end else if (w_dht_start) begin
            r_dht_busy <= 1'b1;
        end
    end

    assign w_dht_start_level = r_dht_busy & ~w_dht_done;


    // SR04 request shaping (pulse -> level)
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_sr04_busy <= 1'b0;
        end else if (w_sr04_done) begin
            r_sr04_busy <= 1'b0;
        end else if (w_sr04_start) begin
            r_sr04_busy <= 1'b1;
        end
    end

    assign w_sr04_start_level = r_sr04_busy & ~w_sr04_done;


    // DHT11 measurement latch (checksum pass only)
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_dht_humidity    <= 16'd0;
            r_dht_temperature <= 16'd0;
        end else if (w_dht_done & w_dht_valid) begin
            r_dht_humidity    <= w_dht_humidity;
            r_dht_temperature <= w_dht_temperature;
        end
    end


    // SR04 measurement latch
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_sr04_distance <= 9'd0;
        end else if (w_sr04_done) begin
            r_sr04_distance <= w_sr04_distance;
        end
    end


    // Stopwatch datapath
    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk         (clk),
        .reset       (reset),

        .run_stop    (w_run_stop),
        .clear       (w_clear),
        .mode        (w_mode_cnt),
        .save        (w_save),
        .return_count(w_return),

        .msec(w_stopwatch_msec),
        .sec (w_stopwatch_sec),
        .min (w_stopwatch_min),
        .hour(w_stopwatch_hour)
    );


    // Watch tick
    tick_gen_100hz U_WATCH_TICK_GEN_100HZ (
        .clk   (clk),
        .reset (reset),
        .o_tick(w_watch_tick)
    );


    // Watch datapath
    watch_datapath U_WATCH_DATAPATH (
        .clk   (clk),
        .reset (reset),

        .i_tick(w_watch_tick),

        .sec_up (w_watch_sec_up),
        .min_up (w_watch_min_up),
        .hour_up(w_watch_hour_up),

        .sec_down (w_watch_sec_down),
        .min_down (w_watch_min_down),
        .hour_down(w_watch_hour_down),

        .msec(w_watch_msec),
        .sec (w_watch_sec),
        .min (w_watch_min),
        .hour(w_watch_hour)
    );


    // DHT11
    dht11_controller U_DHT11_CONTROLLER (
        .clk  (clk),
        .reset(reset),

        .start(w_dht_start_level),

        .humidity   (w_dht_humidity),
        .temperature(w_dht_temperature),

        .done (w_dht_done),
        .valid(w_dht_valid),

        .dht11_io(dht11_io)
    );


    // SR04
    sr04_controller U_SR04_CONTROLLER (
        .clk  (clk),
        .reset(reset),

        .start(w_sr04_start_level),
        .echo (sr04_echo),

        .trig    (sr04_trig),
        .done    (w_sr04_done),
        .distance(w_sr04_distance)
    );


    // Stopwatch / Watch MUX
    mux_2x1_data #(
        .BIT_WIDTH(7)
    ) U_MUX_MSEC (
        .sel    (w_mode[1]),
        .in0    (w_stopwatch_msec),
        .in1    (w_watch_msec),
        .mux_out(w_selected_msec)
    );


    mux_2x1_data #(
        .BIT_WIDTH(6)
    ) U_MUX_SEC (
        .sel    (w_mode[1]),
        .in0    (w_stopwatch_sec),
        .in1    (w_watch_sec),
        .mux_out(w_selected_sec)
    );


    mux_2x1_data #(
        .BIT_WIDTH(6)
    ) U_MUX_MIN (
        .sel    (w_mode[1]),
        .in0    (w_stopwatch_min),
        .in1    (w_watch_min),
        .mux_out(w_selected_min)
    );


    mux_2x1_data #(
        .BIT_WIDTH(5)
    ) U_MUX_HOUR (
        .sel    (w_mode[1]),
        .in0    (w_stopwatch_hour),
        .in1    (w_watch_hour),
        .mux_out(w_selected_hour)
    );


    // FND Controller
    fnd_controller U_FND_CONTROLLER (
        .clk  (clk),
        .reset(reset),

        .msec(w_selected_msec),
        .sec (w_selected_sec),
        .min (w_selected_min),
        .hour(w_selected_hour),

        .display_mode(sw[0]),

        .distance    (r_sr04_distance),
        .humidity    (r_dht_humidity),
        .temperature (r_dht_temperature),

        .dht_sel_temp(w_dht_sel_temp),
        .sw          (w_mode),

        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );


    // ASCII Sender request
    assign w_ascii_send_req =

        // Stopwatch
        (!w_mode[3] && !w_mode[2] && !w_mode[1] &&
        (w_btn_L ||
         w_btn_R ||
         w_btn_U ||
         w_btn_D ||
         w_uart_sw_run ||
         w_uart_sw_stop ||
         w_uart_sw_clear ||
         w_uart_sw_mode))

        ||

        // Watch
        (!w_mode[3] && !w_mode[2] && w_mode[1] &&
        (w_btn_L ||
         w_btn_R ||
         w_btn_U ||
         w_btn_D ||
         w_uart_wc_H ||
         w_uart_wc_M ||
         w_uart_wc_S ||
         w_uart_wc_up ||
         w_uart_wc_down))

        ||

        // SR04 measurement complete
        (w_mode[2] && !w_mode[3] && w_sr04_done)

        ||

        // DHT11 measurement complete (checksum pass only)
        (w_mode[3] && w_dht_done && w_dht_valid);


    // 1 clock delay
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            w_ascii_send <= 1'b0;
        end else begin
            w_ascii_send <= w_ascii_send_req;
        end
    end


    // ASCII Sender
    ascii_sender U_ASCII_SENDER (
        .clk  (clk),
        .reset(reset),

        .i_send(w_ascii_send),

        .sw          (w_mode),
        .display_mode(sw[0]),

        .msec(w_selected_msec),
        .sec (w_selected_sec),
        .min (w_selected_min),
        .hour(w_selected_hour),

        .distance    (r_sr04_distance),
        .humidity    (r_dht_humidity),
        .temperature (r_dht_temperature),

        .dht_sel_temp(w_dht_sel_temp),

        .tx_busy(w_uart_tx_busy),
        .tx_done(w_uart_tx_done),

        .tx_start(w_uart_tx_start),
        .tx_data (w_uart_tx_data)
    );


    // LED
    led_on_off U_LED_ON_OFF (
        .sw_mode(w_mode),
        .led    (led)
    );

endmodule



module uart_rx_fifo #(
    parameter ADDR_WIDTH = 4
) (
    input clk,
    input reset,

    input       i_write,
    input [7:0] i_data,

    output reg       o_valid,
    output reg [7:0] o_data
);

    parameter DEPTH = (1 << ADDR_WIDTH);

    reg [7:0] mem[0:DEPTH-1];

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    reg [ADDR_WIDTH:0] count;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            wr_ptr  <= 0;
            rd_ptr  <= 0;
            count   <= 0;

            o_valid <= 1'b0;
            o_data  <= 8'h00;

        end else begin
            o_valid <= 1'b0;

            if (count != 0) begin
                o_valid <= 1'b1;
                o_data  <= mem[rd_ptr];

                rd_ptr <= rd_ptr + 1'b1;

                if (i_write) begin
                    mem[wr_ptr] <= i_data;
                    wr_ptr      <= wr_ptr + 1'b1;
                end else begin
                    count <= count - 1'b1;
                end

            end else if (i_write) begin
                mem[wr_ptr] <= i_data;
                wr_ptr      <= wr_ptr + 1'b1;

                count <= count + 1'b1;
            end
        end
    end

endmodule



module led_on_off (
    input      [3:0] sw_mode,
    output reg [4:0] led
);

    always @(*) begin
        if (sw_mode[3]) begin
            led = 5'b01000;

        end else if (sw_mode[2]) begin
            led = 5'b00100;

        end else if (sw_mode[1]) begin
            led = 5'b00010;

        end else begin
            led = 5'b00001;
        end
    end

endmodule



module mux_2x1_data #(
    parameter BIT_WIDTH = 7
) (
    input                  sel,
    input  [BIT_WIDTH-1:0] in0,
    input  [BIT_WIDTH-1:0] in1,
    output [BIT_WIDTH-1:0] mux_out
);

    assign mux_out = (sel) ? in1 : in0;

endmodule



module tick_gen_100hz (
    input      clk,
    input      reset,
    output reg o_tick
);

    parameter F_COUNT = 1_000_000;

    reg [$clog2(F_COUNT)-1:0] counter_reg;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick      <= 1'b0;

        end else begin

            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_tick      <= 1'b1;

            end else begin
                counter_reg <= counter_reg + 1'b1;
                o_tick      <= 1'b0;
            end
        end
    end

endmodule
