`timescale 1ns / 1ps


module top_stopwatch_watch(

    input        clk,
    input        reset,
    input        btn_L,    
    input        btn_R,    
    input        btn_U,    
    input        btn_D,    
    input  [1:0] sw,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [4:0] led        
);

    wire w_btn_L, w_btn_R, w_btn_U, w_btn_D;
    wire w_run_stop, w_clear, w_mode, w_save, w_return;
    wire w_watch_tick;
    wire w_watch_sec_up, w_watch_min_up, w_watch_hour_up;
    wire w_watch_sec_down, w_watch_min_down, w_watch_hour_down;

    wire [6:0] w_stopwatch_msec;
    wire [5:0] w_stopwatch_sec;
    wire [5:0] w_stopwatch_min;
    wire [4:0] w_stopwatch_hour;

    wire [6:0] w_watch_msec;
    wire [5:0] w_watch_sec;
    wire [5:0] w_watch_min;
    wire [4:0] w_watch_hour;

    wire [6:0] w_selected_msec;
    wire [5:0] w_selected_sec;
    wire [5:0] w_selected_min;
    wire [4:0] w_selected_hour;

    wire w_btn_L_w, w_btn_L_sw;
    wire w_btn_R_w, w_btn_R_sw;
    wire w_btn_U_w, w_btn_U_sw;
    wire w_btn_D_w, w_btn_D_sw;

    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );

    btn_debounce U_BD_MODE (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_U),
        .o_btn(w_btn_U)
    );

    btn_debounce U_BD_OPTION (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_D),
        .o_btn(w_btn_D)
    );

    stopwatch_control_unit U_STOPWATCH_CONTROL_UNIT (
        .clk          (clk),
        .reset        (reset),
        .i_run_stop   (w_btn_L_sw),
        .i_clear      (w_btn_R_sw),
        .i_mode       (w_btn_U_sw),
        .i_save_return(w_btn_D_sw),
        .o_run_stop   (w_run_stop),
        .o_clear      (w_clear),
        .o_mode       (w_mode),
        .o_save       (w_save),
        .o_return     (w_return)
    );


    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk         (clk),
        .reset       (reset),
        .run_stop    (w_run_stop),
        .clear       (w_clear),
        .mode        (w_mode),
        .save        (w_save),
        .return_count(w_return),
        .msec        (w_stopwatch_msec),
        .sec         (w_stopwatch_sec),
        .min         (w_stopwatch_min),
        .hour        (w_stopwatch_hour)
    );

    tick_gen_100hz U_WATCH_TICK_GEN_100HZ (
        .clk   (clk),
        .reset (reset),
        .o_tick(w_watch_tick)
    );

    watch_control_unit U_WATCH_CONTROL_UNIT (
        .clk        (clk),
        .reset      (reset),
        .i_sec_up   (w_btn_R_w),
        .i_min_up   (w_btn_U_w),
        .i_hour_up  (w_btn_L_w),
        .i_minus    (w_btn_D_w),
        .o_sec_up   (w_watch_sec_up),
        .o_min_up   (w_watch_min_up),
        .o_hour_up  (w_watch_hour_up),
        .o_sec_down (w_watch_sec_down),
        .o_min_down (w_watch_min_down),
        .o_hour_down(w_watch_hour_down)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk      (clk),
        .reset    (reset),
        .i_tick   (w_watch_tick),
        .sec_up   (w_watch_sec_up),
        .min_up   (w_watch_min_up),
        .hour_up  (w_watch_hour_up),
        .sec_down (w_watch_sec_down),
        .min_down (w_watch_min_down),
        .hour_down(w_watch_hour_down),
        .msec     (w_watch_msec),
        .sec      (w_watch_sec),
        .min      (w_watch_min),
        .hour     (w_watch_hour)
    );

    mux_2x1_data #(
        .BIT_WIDTH(7)
    ) U_MUX_MSEC (
        .sel    (sw[1]),
        .in0    (w_stopwatch_msec),
        .in1    (w_watch_msec),
        .mux_out(w_selected_msec)
    );

    mux_2x1_data #(
        .BIT_WIDTH(6)
    ) U_MUX_SEC (
        .sel    (sw[1]),
        .in0    (w_stopwatch_sec),
        .in1    (w_watch_sec),
        .mux_out(w_selected_sec)
    );

    mux_2x1_data #(
        .BIT_WIDTH(6)
    ) U_MUX_MIN (
        .sel    (sw[1]),
        .in0    (w_stopwatch_min),
        .in1    (w_watch_min),
        .mux_out(w_selected_min)
    );

    mux_2x1_data #(
        .BIT_WIDTH(5)
    ) U_MUX_HOUR (
        .sel    (sw[1]),
        .in0    (w_stopwatch_hour),
        .in1    (w_watch_hour),
        .mux_out(w_selected_hour)
    );

    fnd_controller U_FND_CNTL (
        .clk         (clk),
        .reset       (reset),
        .msec        (w_selected_msec),
        .sec         (w_selected_sec),
        .min         (w_selected_min),
        .hour        (w_selected_hour),
        .display_mode(sw[0]),
        .fnd_com     (fnd_com),
        .fnd_data    (fnd_data)
    );

    led_on_off U_LED_ON_OFF (
        .sw_mode(sw),
        .led    (led)
    );

    and_gate U_AND_1 (
    .in0(w_btn_L),
    .in1(~sw[1]),
    .and_out(w_btn_L_sw)
    );

    and_gate U_AND_2 (
    .in0(w_btn_L),
    .in1(sw[1]),
    .and_out(w_btn_L_w)
    );

    and_gate U_AND_3 (
    .in0(w_btn_R),
    .in1(~sw[1]),
    .and_out(w_btn_R_sw)
    );

    and_gate U_AND_4 (
    .in0(w_btn_R),
    .in1(sw[1]),
    .and_out(w_btn_R_w)
    );

    and_gate U_AND_5 (
    .in0(w_btn_U),
    .in1(~sw[1]),
    .and_out(w_btn_U_sw)
    );

    and_gate U_AND_6 (
    .in0(w_btn_U),
    .in1(sw[1]),
    .and_out(w_btn_U_w)
    ); 

    and_gate U_AND_7 (
    .in0(w_btn_D),
    .in1(~sw[1]),
    .and_out(w_btn_D_sw)
    );

    and_gate U_AND_8 (
    .in0(w_btn_D),
    .in1(sw[1]),
    .and_out(w_btn_D_w)
    );


endmodule

module and_gate (
    input in0,
    input in1,
    output and_out
);

    assign and_out = in0 & in1;


endmodule

module led_on_off (
    input [1:0] sw_mode,
    output reg [4:0] led
);

    always @(*) begin
        case(sw_mode)
        2'b00: led = 5'b00001;
        2'b01: led = 5'b00010;
        2'b10: led = 5'b00100;
        2'b11: led = 5'b01000;
        default: led = 5'b00000;
        endcase
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
    output [MSEC_WIDTH - 1 : 0] msec,
    output [ SEC_WIDTH - 1 : 0] sec,
    output [ MIN_WIDTH - 1 : 0] min,
    output [HOUR_WIDTH - 1 : 0] hour
);

    //parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;

    wire w_tick_100hz, w_tick_sec, w_tick_min, w_tick_hour;

    wire w_reset = reset | clear;

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


module tick_gen_100hz (
    input clk,
    input reset,
    output reg o_tick
);
    parameter F_COUNT = 1_000_000;  

    reg [$clog2(F_COUNT) - 1:0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick      <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (F_COUNT - 1)) begin
                counter_reg <= 0;
                o_tick      <= 1'b1;
            end else begin
                o_tick <= 1'b0;
            end
        end
    end

endmodule


module time_counter #(
    parameter BIT_WIDTH = 7,
    parameter TIMES = 100
) (
    input                      clk,
    input                      reset,
    input                      i_tick,
    input                      mode,
    input                      run_stop,
    input                      clear,
    input                      save,
    input                      return_count,
    output     [BIT_WIDTH-1:0] time_count,
    output reg                 o_tick
);

    reg [$clog2(TIMES)-1:0] counter_reg;
    reg [$clog2(TIMES)-1:0] save_reg;

    assign time_count = counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick      <= 1'b0;
            save_reg    <= 0;
        end/*else if (clear) begin
            counter_reg <= 0;
            save_reg    <= 0;
            o_tick      <= 1'b0;
        end*/ else begin
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
