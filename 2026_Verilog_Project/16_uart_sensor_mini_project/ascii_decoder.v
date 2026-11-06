`timescale 1ns / 1ps

module ascii_decoder (
    input       clk,
    input       reset,
    input       i_valid,     // 1클럭 펄스 (FIFO pop 시점)
    input [7:0] i_data,
    input       i_run_state, // control_unit의 o_run_stop

    // 모드 (레벨 + 변경 펄스)
    output reg [1:0] o_mode_sel,
    output reg       o_mode_valid,

    // 스탑워치
    output reg o_sw_run,
    output reg o_sw_stop,
    output reg o_sw_clear,
    output reg o_sw_mode,

    // 시계
    output reg o_wc_H,
    output reg o_wc_M,
    output reg o_wc_S,
    output reg o_wc_up,
    output reg o_wc_down,

    // DHT11
    output reg o_dht_start,
    output reg o_dht_sel_temp, // 0=습도, 1=온도 (레벨 유지)

    // SR04 (추후)
    output reg o_sr04_start
);

    localparam [1:0] MODE_STOP  = 2'd0,
                     MODE_WATCH = 2'd1,
                     MODE_DIST  = 2'd2,
                     MODE_DHT   = 2'd3;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            o_mode_sel     <= MODE_STOP;
            o_mode_valid   <= 1'b0;

            o_sw_run       <= 1'b0;
            o_sw_stop      <= 1'b0;
            o_sw_clear     <= 1'b0;
            o_sw_mode      <= 1'b0;

            o_wc_H         <= 1'b0;
            o_wc_M         <= 1'b0;
            o_wc_S         <= 1'b0;
            o_wc_up        <= 1'b0;
            o_wc_down      <= 1'b0;

            o_dht_start    <= 1'b0;
            o_dht_sel_temp <= 1'b0;
            o_sr04_start   <= 1'b0;
        end else begin
            // 펄스 출력만 매 클럭 클리어 (레벨 출력은 유지)
            o_mode_valid <= 1'b0;

            o_sw_run     <= 1'b0;
            o_sw_stop    <= 1'b0;
            o_sw_clear   <= 1'b0;
            o_sw_mode    <= 1'b0;

            o_wc_H       <= 1'b0;
            o_wc_M       <= 1'b0;
            o_wc_S       <= 1'b0;
            o_wc_up      <= 1'b0;
            o_wc_down    <= 1'b0;

            o_dht_start  <= 1'b0;
            o_sr04_start <= 1'b0;

            if (i_valid) begin
                case (i_data)
                    // ---------- 스탑워치 (소문자) ----------
                    "r": begin
                        if (!i_run_state) o_sw_run <= 1'b1;
                        o_mode_sel   <= MODE_STOP;
                        o_mode_valid <= 1'b1;
                    end
                    "s": begin
                        if (i_run_state) o_sw_stop <= 1'b1;
                        o_mode_sel   <= MODE_STOP;
                        o_mode_valid <= 1'b1;
                    end
                    "c": begin
                        o_sw_clear   <= 1'b1;
                        o_mode_sel   <= MODE_STOP;
                        o_mode_valid <= 1'b1;
                    end
                    "m": begin
                        o_sw_mode    <= 1'b1;
                        o_mode_sel   <= MODE_STOP;
                        o_mode_valid <= 1'b1;
                    end

                    // ---------- 시계 (대문자) ----------
                    "U": o_wc_up <= 1'b1;  // 방향만 변경, 모드 유지
                    "D": o_wc_down <= 1'b1;
                    "H": begin
                        o_wc_H       <= 1'b1;
                        o_mode_sel   <= MODE_WATCH;
                        o_mode_valid <= 1'b1;
                    end
                    "M": begin
                        o_wc_M       <= 1'b1;
                        o_mode_sel   <= MODE_WATCH;
                        o_mode_valid <= 1'b1;
                    end
                    "S": begin
                        o_wc_S       <= 1'b1;
                        o_mode_sel   <= MODE_WATCH;
                        o_mode_valid <= 1'b1;
                    end

                    // ---------- 센서 (소문자) ----------
                    "h": begin  // 습도
                        o_dht_start    <= 1'b1;
                        o_dht_sel_temp <= 1'b0;
                        o_mode_sel     <= MODE_DHT;
                        o_mode_valid   <= 1'b1;
                    end
                    "t": begin  // 온도
                        o_dht_start    <= 1'b1;
                        o_dht_sel_temp <= 1'b1;
                        o_mode_sel     <= MODE_DHT;
                        o_mode_valid   <= 1'b1;
                    end
                    "d": begin  // 거리 (추후)
                        o_sr04_start <= 1'b1;
                        o_mode_sel   <= MODE_DIST;
                        o_mode_valid <= 1'b1;
                    end

                    default: ;  // 미정의 문자 무시
                endcase
            end
        end
    end

endmodule
