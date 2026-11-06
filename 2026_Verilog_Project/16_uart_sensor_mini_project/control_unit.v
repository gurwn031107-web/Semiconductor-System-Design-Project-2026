`timescale 1ns / 1ps

module control_unit (
    input        clk,
    input        reset,

    input  [3:0] sw,

    input        i_btn_L,
    input        i_btn_R,
    input        i_btn_U,
    input        i_btn_D,

    // Stopwatch UART
    input        i_uart_run,
    input        i_uart_stop,
    input        i_uart_clear,
    input        i_uart_mode,

    // Watch UART
    input        i_uart_sec_up,
    input        i_uart_min_up,
    input        i_uart_hour_up,
    input        i_uart_up,
    input        i_uart_down,

    // SR04 UART
    input        i_uart_sr04_start,

    // DHT11 UART
    input        i_uart_dht_start,
    input        i_uart_dht_sel_temp,

    // Stopwatch
    output       o_run_stop,
    output       o_clear,
    output       o_mode,
    output       o_save,
    output       o_return,

    // Watch
    output       o_sec_up,
    output       o_min_up,
    output       o_hour_up,

    output       o_sec_down,
    output       o_min_down,
    output       o_hour_down,

    // SR04
    output       o_sr04_start,

    // DHT11
    output       o_dht_start,
    output       o_dht_sel_temp
);

    parameter STOP   = 3'd0;
    parameter RUN    = 3'd1;
    parameter CLEAR  = 3'd2;
    parameter MODE   = 3'd3;
    parameter SAVE   = 3'd4;
    parameter RETURN = 3'd5;

    parameter SELECT_SEC  = 2'd0;
    parameter SELECT_MIN  = 2'd1;
    parameter SELECT_HOUR = 2'd2;

    parameter UP   = 1'b0;
    parameter DOWN = 1'b1;


    reg [2:0] sw_c_state;
    reg [2:0] sw_n_state;

    reg [1:0] watch_c_state;
    reg [1:0] watch_n_state;

    reg watch_dir_reg;
    reg watch_dir_next;


    reg run_stop_reg;
    reg run_stop_next;

    reg clear_reg;
    reg clear_next;

    reg mode_reg;
    reg mode_next;

    reg save_reg;
    reg save_next;

    reg return_reg;
    reg return_next;


    reg sec_up_reg;
    reg sec_up_next;

    reg min_up_reg;
    reg min_up_next;

    reg hour_up_reg;
    reg hour_up_next;

    reg sec_down_reg;
    reg sec_down_next;

    reg min_down_reg;
    reg min_down_next;

    reg hour_down_reg;
    reg hour_down_next;


    reg sr04_start_reg;
    reg sr04_start_next;


    reg dht_start_reg;
    reg dht_start_next;

    reg dht_sel_temp_reg;
    reg dht_sel_temp_next;


    assign o_run_stop = run_stop_reg;
    assign o_clear    = clear_reg;
    assign o_mode     = mode_reg;
    assign o_save     = save_reg;
    assign o_return   = return_reg;

    assign o_sec_up   = sec_up_reg;
    assign o_min_up   = min_up_reg;
    assign o_hour_up  = hour_up_reg;

    assign o_sec_down  = sec_down_reg;
    assign o_min_down  = min_down_reg;
    assign o_hour_down = hour_down_reg;

    assign o_sr04_start = sr04_start_reg;

    assign o_dht_start    = dht_start_reg;
    assign o_dht_sel_temp = dht_sel_temp_reg;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            sw_c_state    <= STOP;
            watch_c_state <= SELECT_SEC;

            watch_dir_reg <= UP;

            run_stop_reg <= 1'b0;
            clear_reg    <= 1'b0;
            mode_reg     <= 1'b0;
            save_reg     <= 1'b0;
            return_reg   <= 1'b0;

            sec_up_reg   <= 1'b0;
            min_up_reg   <= 1'b0;
            hour_up_reg  <= 1'b0;

            sec_down_reg  <= 1'b0;
            min_down_reg  <= 1'b0;
            hour_down_reg <= 1'b0;

            sr04_start_reg <= 1'b0;

            dht_start_reg    <= 1'b0;
            dht_sel_temp_reg <= 1'b0;

        end else begin
            sw_c_state    <= sw_n_state;
            watch_c_state <= watch_n_state;

            watch_dir_reg <= watch_dir_next;

            run_stop_reg <= run_stop_next;
            clear_reg    <= clear_next;
            mode_reg     <= mode_next;
            save_reg     <= save_next;
            return_reg   <= return_next;

            sec_up_reg   <= sec_up_next;
            min_up_reg   <= min_up_next;
            hour_up_reg  <= hour_up_next;

            sec_down_reg  <= sec_down_next;
            min_down_reg  <= min_down_next;
            hour_down_reg <= hour_down_next;

            sr04_start_reg <= sr04_start_next;

            dht_start_reg    <= dht_start_next;
            dht_sel_temp_reg <= dht_sel_temp_next;
        end
    end


    // Stopwatch
    always @(*) begin
        sw_n_state = sw_c_state;

        run_stop_next = run_stop_reg;
        clear_next    = 1'b0;
        mode_next     = mode_reg;
        save_next     = 1'b0;
        return_next   = 1'b0;

        case (sw_c_state)

            STOP: begin
                run_stop_next = 1'b0;

                if (i_uart_run) begin
                    sw_n_state = RUN;

                end else if (i_uart_clear) begin
                    sw_n_state = CLEAR;

                end else if (i_uart_mode) begin
                    sw_n_state = MODE;

                end else if (!sw[3] && !sw[2] && !sw[1]) begin

                    if (i_btn_L) begin
                        sw_n_state = RUN;

                    end else if (i_btn_R) begin
                        sw_n_state = CLEAR;

                    end else if (i_btn_U) begin
                        sw_n_state = MODE;

                    end else if (i_btn_D) begin
                        sw_n_state = RETURN;
                    end
                end
            end


            RUN: begin
                run_stop_next = 1'b1;

                if (i_uart_stop) begin
                    sw_n_state = STOP;

                end else if (i_uart_clear) begin
                    sw_n_state = CLEAR;

                end else if (i_uart_mode) begin
                    sw_n_state = MODE;

                end else if (!sw[3] && !sw[2] && !sw[1]) begin

                    if (i_btn_L) begin
                        sw_n_state = STOP;

                    end else if (i_btn_R) begin
                        sw_n_state = CLEAR;

                    end else if (i_btn_U) begin
                        sw_n_state = MODE;

                    end else if (i_btn_D) begin
                        sw_n_state = SAVE;
                    end
                end
            end


            CLEAR: begin
                run_stop_next = 1'b0;
                clear_next    = 1'b1;
                sw_n_state    = STOP;
            end


            MODE: begin
                run_stop_next = 1'b0;
                mode_next     = ~mode_reg;
                sw_n_state    = STOP;
            end


            SAVE: begin
                run_stop_next = 1'b1;
                save_next     = 1'b1;
                sw_n_state    = RUN;
            end


            RETURN: begin
                run_stop_next = 1'b0;
                return_next   = 1'b1;
                sw_n_state    = STOP;
            end


            default: begin
                sw_n_state = STOP;
            end

        endcase
    end


    // Watch
    always @(*) begin
        watch_n_state = watch_c_state;
        watch_dir_next = watch_dir_reg;

        sec_up_next   = 1'b0;
        min_up_next   = 1'b0;
        hour_up_next  = 1'b0;

        sec_down_next  = 1'b0;
        min_down_next  = 1'b0;
        hour_down_next = 1'b0;


        if (i_uart_up) begin
            watch_dir_next = UP;

        end else if (i_uart_down) begin
            watch_dir_next = DOWN;

        end else if (!sw[3] && !sw[2] && sw[1] && i_btn_D) begin
            watch_dir_next = DOWN;
        end


        if (i_uart_sec_up) begin
            watch_n_state = SELECT_SEC;

            if (watch_dir_reg == UP) begin
                sec_up_next = 1'b1;
            end else begin
                sec_down_next = 1'b1;
            end

        end else if (i_uart_min_up) begin
            watch_n_state = SELECT_MIN;

            if (watch_dir_reg == UP) begin
                min_up_next = 1'b1;
            end else begin
                min_down_next = 1'b1;
            end

        end else if (i_uart_hour_up) begin
            watch_n_state = SELECT_HOUR;

            if (watch_dir_reg == UP) begin
                hour_up_next = 1'b1;
            end else begin
                hour_down_next = 1'b1;
            end

        end else if (!sw[3] && !sw[2] && sw[1]) begin

            if (i_btn_R) begin
                watch_n_state = SELECT_SEC;

                if (watch_dir_reg == UP) begin
                    sec_up_next = 1'b1;
                end else begin
                    sec_down_next = 1'b1;
                end

            end else if (i_btn_U) begin
                watch_n_state = SELECT_MIN;

                if (watch_dir_reg == UP) begin
                    min_up_next = 1'b1;
                end else begin
                    min_down_next = 1'b1;
                end

            end else if (i_btn_L) begin
                watch_n_state = SELECT_HOUR;

                if (watch_dir_reg == UP) begin
                    hour_up_next = 1'b1;
                end else begin
                    hour_down_next = 1'b1;
                end
            end
        end
    end


    // SR04
    always @(*) begin
        sr04_start_next = 1'b0;

        if (i_uart_sr04_start) begin
            sr04_start_next = 1'b1;

        end else if (sw[2] && !sw[3]) begin

            if (i_btn_L) begin
                sr04_start_next = 1'b1;
            end
        end
    end


    // DHT11
    always @(*) begin
        dht_start_next    = 1'b0;
        dht_sel_temp_next = dht_sel_temp_reg;

        if (i_uart_dht_start) begin
            dht_start_next    = 1'b1;
            dht_sel_temp_next = i_uart_dht_sel_temp;

        end else if (sw[3]) begin

            // btn_L = humidity
            if (i_btn_L) begin
                dht_start_next    = 1'b1;
                dht_sel_temp_next = 1'b0;

            // btn_R = temperature
            end else if (i_btn_R) begin
                dht_start_next    = 1'b1;
                dht_sel_temp_next = 1'b1;
            end
        end
    end

endmodule
