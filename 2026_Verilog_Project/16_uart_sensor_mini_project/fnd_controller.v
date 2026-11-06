`timescale 1ns / 1ps

module fnd_controller #(
    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH  = 6,
    parameter MIN_WIDTH  = 6,
    parameter HOUR_WIDTH = 5
) (
    input                   clk,
    input                   reset,

    // Stopwatch / Watch
    input  [MSEC_WIDTH-1:0] msec,
    input  [ SEC_WIDTH-1:0] sec,
    input  [ MIN_WIDTH-1:0] min,
    input  [HOUR_WIDTH-1:0] hour,
    input                   display_mode,

    // Sensor
    input  [8:0]            distance,
    input  [15:0]           humidity,
    input  [15:0]           temperature,
    input                   dht_sel_temp,
    input  [3:0]            sw,

    output [3:0]             fnd_com,
    output [7:0]             fnd_data
);

    // Stopwatch / Watch digit
    wire [3:0] w_msec_digit_1;
    wire [3:0] w_msec_digit_10;

    wire [3:0] w_sec_digit_1;
    wire [3:0] w_sec_digit_10;

    wire [3:0] w_min_digit_1;
    wire [3:0] w_min_digit_10;

    wire [3:0] w_hour_digit_1;
    wire [3:0] w_hour_digit_10;


    // Sensor digit
    wire [15:0] w_sensor_value;

    wire [3:0] w_sensor_digit_1;
    wire [3:0] w_sensor_digit_10;
    wire [3:0] w_sensor_digit_100;
    wire [3:0] w_sensor_digit_1000;


    // MUX
    wire [3:0] w_msec_sec;
    wire [3:0] w_min_hour;
    wire [3:0] w_time_bcd;
    wire [3:0] w_sensor_bcd;
    wire [3:0] w_bcd;


    wire [2:0] w_digit_sel;
    wire       w_1khz;
    wire       w_dot_onoff;

    wire       w_sensor_mode;


    // Sensor mode
    assign w_sensor_mode = sw[3] | sw[2];


    // Sensor value select
    assign w_sensor_value =
        (sw[3]) ? ((dht_sel_temp) ? temperature[15:8]
                                  : humidity[15:8]) :
        (sw[2]) ? distance :
                  16'd0;


    // Clock divider
    clk_div U_CLK_DIV (
        .clk   (clk),
        .reset (reset),
        .o_1khz(w_1khz)
    );


    // Digit counter
    counter_8 U_COUNTER_8 (
        .clk      (w_1khz),
        .reset    (reset),
        .digit_sel(w_digit_sel)
    );


    // FND common
    decoder_2x4 U_DECODER_2X4 (
        .digit_sel(w_digit_sel[1:0]),
        .fnd_com  (fnd_com)
    );


    // Dot
    comparator_dot #(
        .MSEC_WIDTH(MSEC_WIDTH)
    ) U_COMPARATOR_DOT (
        .msec     (msec),
        .dot_onoff(w_dot_onoff)
    );


    // msec
    digit_spliter #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_DIGIT_SPLITTER_MSEC (
        .ds_in   (msec),
        .digit_1 (w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );


    // sec
    digit_spliter #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_DIGIT_SPLITTER_SEC (
        .ds_in   (sec),
        .digit_1 (w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );


    // min
    digit_spliter #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_DIGIT_SPLITTER_MIN (
        .ds_in   (min),
        .digit_1 (w_min_digit_1),
        .digit_10(w_min_digit_10)
    );


    // hour
    digit_spliter #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_DIGIT_SPLITTER_HOUR (
        .ds_in   (hour),
        .digit_1 (w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );


    // Sensor 4 digit splitter
    digit_spliter_4 #(
        .BIT_WIDTH(16)
    ) U_DIGIT_SPLITTER_SENSOR (
        .ds_in     (w_sensor_value),
        .digit_1   (w_sensor_digit_1),
        .digit_10  (w_sensor_digit_10),
        .digit_100 (w_sensor_digit_100),
        .digit_1000(w_sensor_digit_1000)
    );


    // msec / sec display
    mux_8x1 U_MUX_8X1_MSEC_SEC (
        .sel    (w_digit_sel),

        .in0    (w_msec_digit_1),
        .in1    (w_msec_digit_10),
        .in2    (w_sec_digit_1),
        .in3    (w_sec_digit_10),

        .in4    (4'hf),
        .in5    (4'hf),
        .in6    ({3'b111, w_dot_onoff}),
        .in7    (4'hf),

        .mux_out(w_msec_sec)
    );


    // min / hour display
    mux_8x1 U_MUX_8X1_MIN_HOUR (
        .sel    (w_digit_sel),

        .in0    (w_min_digit_1),
        .in1    (w_min_digit_10),
        .in2    (w_hour_digit_1),
        .in3    (w_hour_digit_10),

        .in4    (4'hf),
        .in5    (4'hf),
        .in6    ({3'b111, w_dot_onoff}),
        .in7    (4'hf),

        .mux_out(w_min_hour)
    );


    // Stopwatch / Watch display select
    mux_2x1 U_MUX_2X1_DISPLAY (
        .sel    (display_mode),
        .in0    (w_msec_sec),
        .in1    (w_min_hour),
        .mux_out(w_time_bcd)
    );


    // Sensor display
    mux_8x1 U_MUX_8X1_SENSOR (
        .sel    (w_digit_sel),

        .in0    (w_sensor_digit_1),
        .in1    (w_sensor_digit_10),
        .in2    (w_sensor_digit_100),
        .in3    (w_sensor_digit_1000),

        .in4    (4'hf),
        .in5    (4'hf),
        .in6    (4'hf),
        .in7    (4'hf),

        .mux_out(w_sensor_bcd)
    );


    // Time / Sensor select
    mux_2x1 U_MUX_2X1_TIME_SENSOR (
        .sel    (w_sensor_mode),
        .in0    (w_time_bcd),
        .in1    (w_sensor_bcd),
        .mux_out(w_bcd)
    );


    // BCD to FND
    bcd U_BCD (
        .bcd_in (w_bcd),
        .bcd_out(fnd_data)
    );

endmodule



module comparator_dot #(
    parameter MSEC_WIDTH = 7
) (
    input  [MSEC_WIDTH-1:0] msec,
    output                  dot_onoff
);

    assign dot_onoff = (msec < 50);

endmodule



module clk_div (
    input  clk,
    input  reset,
    output o_1khz
);

    reg [15:0] counter_reg;
    reg        clk_reg;

    assign o_1khz = clk_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            clk_reg     <= 1'b0;
        end else begin
            if (counter_reg == 16'd49999) begin
                counter_reg <= 0;
                clk_reg     <= ~clk_reg;
            end else begin
                counter_reg <= counter_reg + 1'b1;
            end
        end
    end

endmodule



module counter_8 (
    input        clk,
    input        reset,
    output [2:0] digit_sel
);

    reg [2:0] counter_reg;

    assign digit_sel = counter_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_reg + 1'b1;
        end
    end

endmodule



module decoder_2x4 (
    input      [1:0] digit_sel,
    output reg [3:0] fnd_com
);

    always @(*) begin
        case (digit_sel)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end

endmodule



module digit_spliter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH-1:0] ds_in,
    output [3:0]           digit_1,
    output [3:0]           digit_10
);

    assign digit_1  = ds_in % 10;
    assign digit_10 = (ds_in / 10) % 10;

endmodule



module digit_spliter_4 #(
    parameter BIT_WIDTH = 16
) (
    input  [BIT_WIDTH-1:0] ds_in,

    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);

    assign digit_1    = ds_in % 10;
    assign digit_10   = (ds_in / 10) % 10;
    assign digit_100  = (ds_in / 100) % 10;
    assign digit_1000 = (ds_in / 1000) % 10;

endmodule



module mux_2x1 (
    input        sel,
    input  [3:0] in0,
    input  [3:0] in1,
    output [3:0] mux_out
);

    assign mux_out = sel ? in1 : in0;

endmodule



module mux_8x1 (
    input      [2:0] sel,

    input      [3:0] in0,
    input      [3:0] in1,
    input      [3:0] in2,
    input      [3:0] in3,
    input      [3:0] in4,
    input      [3:0] in5,
    input      [3:0] in6,
    input      [3:0] in7,

    output reg [3:0] mux_out
);

    always @(*) begin
        case (sel)
            3'b000: mux_out = in0;
            3'b001: mux_out = in1;
            3'b010: mux_out = in2;
            3'b011: mux_out = in3;
            3'b100: mux_out = in4;
            3'b101: mux_out = in5;
            3'b110: mux_out = in6;
            3'b111: mux_out = in7;
            default: mux_out = 4'hf;
        endcase
    end

endmodule



module bcd (
    input      [3:0] bcd_in,
    output reg [7:0] bcd_out
);

    always @(*) begin
        case (bcd_in)
            4'h0: bcd_out = 8'hc0;
            4'h1: bcd_out = 8'hf9;
            4'h2: bcd_out = 8'ha4;
            4'h3: bcd_out = 8'hb0;
            4'h4: bcd_out = 8'h99;
            4'h5: bcd_out = 8'h92;
            4'h6: bcd_out = 8'h82;
            4'h7: bcd_out = 8'hf8;
            4'h8: bcd_out = 8'h80;
            4'h9: bcd_out = 8'h90;
            4'ha: bcd_out = 8'h88;
            4'hb: bcd_out = 8'h83;
            4'hc: bcd_out = 8'hc6;
            4'hd: bcd_out = 8'ha1;
            4'he: bcd_out = 8'h7f;
            4'hf: bcd_out = 8'hff;
            default: bcd_out = 8'hff;
        endcase
    end

endmodule