`timescale 1ns / 1ps


module stopwatch_control_unit (
    input  clk,
    input  reset,
    input  i_run_stop,
    input  i_clear,
    input  i_mode,
    input  i_save_return,
    output o_run_stop,
    output o_clear,
    output o_mode,
    output o_save,
    output o_return
);

    parameter STOP = 3'd0;
    parameter RUN = 3'd1;
    parameter CLEAR = 3'd2;
    parameter MODE = 3'd3;
    parameter SAVE = 3'd4;
    parameter RETURN = 3'd5;

    reg [2:0] c_state;
    reg [2:0] n_state;

    reg run_stop_reg, run_stop_next;
    reg clear_reg, clear_next;
    reg mode_reg, mode_next;
    reg save_reg, save_next;
    reg return_reg, return_next;

    assign o_run_stop = run_stop_reg;
    assign o_clear = clear_reg;
    assign o_mode = mode_reg;
    assign o_save = save_reg;
    assign o_return = return_reg;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= STOP;
            run_stop_reg <= 1'b0;
            clear_reg <= 1'b0;
            mode_reg <= 1'b0;
            save_reg <= 1'b0;
            return_reg <= 1'b0;
        end else begin
            c_state      <= n_state;
            run_stop_reg <= run_stop_next;
            clear_reg    <= clear_next;
            mode_reg     <= mode_next;
            save_reg     <= save_next;
            return_reg   <= return_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        run_stop_next = run_stop_reg;
        mode_next = mode_reg;
        clear_next = clear_reg;
        save_next = 1'b0;
        return_next = 1'b0;

        case (c_state)

            STOP: begin
                run_stop_next = 1'b0;

                if (i_run_stop) begin
                    n_state = RUN;
                end else if (i_clear) begin
                    n_state = CLEAR;
                end else if (i_mode) begin
                    n_state = MODE;
                end else if (i_save_return) begin
                    n_state = RETURN;
                end
            end


            RUN: begin
                run_stop_next = 1'b1;

                if (i_run_stop) begin
                    n_state = STOP;
                end else if (i_save_return) begin
                    n_state = SAVE;
                end
            end


            CLEAR: begin
                run_stop_next = 1'b0;
                clear_next    = 1'b1;
                n_state       = STOP;
            end


            MODE: begin
                run_stop_next = 1'b0;
                mode_next     = ~mode_reg;
                n_state       = STOP;
            end


            SAVE: begin
                run_stop_next = 1'b1;
                save_next     = 1'b1;
                n_state       = RUN;
            end


            RETURN: begin
                run_stop_next = 1'b0;
                return_next   = 1'b1;
                n_state       = STOP;
            end

        endcase
    end

endmodule