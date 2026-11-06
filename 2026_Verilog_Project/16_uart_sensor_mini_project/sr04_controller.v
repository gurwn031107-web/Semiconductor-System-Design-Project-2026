`timescale 1ns / 1ps


module sr04_controller (
    input            clk,
    input            reset,
    input            start,
    input            echo,
    output reg       trig,
    output           done,
    output     [8:0] distance
);

    wire w_o_tick_us;

    // fsm control_unit
    localparam [2:0] IDLE = 0, START = 1, WAIT = 2, COUNT = 3, DISTANCE = 4;
    reg [2:0] c_state, n_state;
    reg run_stop;
    reg clear;
    reg [$clog2(58*400)-1:0] counter_reg, counter_next;
    reg [8:0] distance_reg, distance_next;
    reg done_reg, done_next;  // done 을 레지스터로

    assign distance = distance_reg;
    assign done     = done_reg;

    tick_us #(
        .F_COUNT(100)
    ) U_TICK_US (
        .clk      (clk),
        .reset    (reset),
        .run_stop (run_stop),
        .clear    (clear),
        .o_tick_us(w_o_tick_us)
    );

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state      <= IDLE;
            counter_reg  <= 0;
            distance_reg <= 0;
            done_reg     <= 1'b0;
        end else begin
            c_state <= n_state;
            counter_reg <= counter_next;
            distance_reg <= distance_next;
            done_reg <= done_next;  // distance_reg 와 같은 엣지에 갱신
        end
    end

    // next, output
    always @(*) begin
        n_state       = c_state;
        counter_next  = counter_reg;
        distance_next = distance_reg;
        done_next     = 1'b0;  // 기본 0 -> done 은 1클럭 펄스
        run_stop      = 1'b0;
        clear         = 1'b0;
        trig          = 1'b0;
        case (c_state)
            IDLE: begin
                run_stop     = 1'b0;
                clear        = 1'b1;
                trig         = 1'b0;
                counter_next = 0;
                if (start) begin
                    n_state = START;
                end
            end

            START: begin
                run_stop = 1'b1;
                clear    = 1'b0;
                trig     = 1'b1;
                if (w_o_tick_us) begin
                    counter_next = counter_reg + 1;
                end
                if (counter_reg == 11) begin
                    n_state = WAIT;
                end
            end

            WAIT: begin
                run_stop = 1'b0;
                clear    = 1'b1;
                trig     = 1'b0;
                if (echo) begin
                    n_state      = COUNT;
                    counter_next = 0;
                end
            end

            COUNT: begin
                run_stop = 1'b1;
                if (!echo) begin
                    n_state = DISTANCE;
                end else if (w_o_tick_us) begin
                    counter_next = counter_reg + 1;
                end
            end

            DISTANCE: begin
                n_state = IDLE;
                distance_next = (counter_reg >> 6) + (counter_reg >> 9);
                done_next     = 1'b1;      // distance_next 와 함께 다음 클럭에 반영
            end
        endcase
    end

endmodule

module tick_us (
    input  clk,
    input  reset,
    input  run_stop,
    input  clear,
    output o_tick_us
);

    parameter F_COUNT = 100;

    reg [$clog2(F_COUNT)-1:0] counter_reg;
    reg tick_us_reg;

    assign o_tick_us = tick_us_reg;

    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= 0;
            tick_us_reg <= 0;
        end else if (run_stop) begin
            if (counter_reg == (F_COUNT - 1)) begin
                counter_reg <= 0;
                tick_us_reg <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                tick_us_reg <= 1'b0;
            end
        end else begin
            //counter_reg <= 0;
            tick_us_reg <= 1'b0;
        end
    end



endmodule