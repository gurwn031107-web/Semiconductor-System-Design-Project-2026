`timescale 1ns / 1ps

module watch_control_unit (
    input  clk,
    input  reset,
    input  i_sec_up,
    input  i_min_up,
    input  i_hour_up,
    input  i_minus,
    output o_sec_up,
    output o_min_up,
    output o_hour_up,
    output o_sec_down,
    output o_min_down,
    output o_hour_down
);

    parameter SELECT_SEC  = 2'd0;
    parameter SELECT_MIN  = 2'd1;
    parameter SELECT_HOUR = 2'd2;

    reg [1:0] c_state, n_state;

    reg sec_up_reg, sec_up_next;
    reg min_up_reg, min_up_next;
    reg hour_up_reg, hour_up_next;
    reg sec_down_reg, sec_down_next;
    reg min_down_reg, min_down_next;
    reg hour_down_reg, hour_down_next;

    assign o_sec_up    = sec_up_reg;
    assign o_min_up    = min_up_reg;
    assign o_hour_up   = hour_up_reg;
    assign o_sec_down  = sec_down_reg;
    assign o_min_down  = min_down_reg;
    assign o_hour_down = hour_down_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state    <= SELECT_SEC;
            sec_up_reg    <= 1'b0;
            min_up_reg    <= 1'b0;
            hour_up_reg   <= 1'b0;
            sec_down_reg  <= 1'b0;
            min_down_reg  <= 1'b0;
            hour_down_reg <= 1'b0;
        end else begin
            c_state       <= n_state;
            sec_up_reg    <= sec_up_next;
            min_up_reg    <= min_up_next;
            hour_up_reg   <= hour_up_next;
            sec_down_reg  <= sec_down_next;
            min_down_reg  <= min_down_next;
            hour_down_reg <= hour_down_next;
        end
    end

    always @(*) begin
        n_state    = c_state;
        sec_up_next    = 1'b0;
        min_up_next    = 1'b0;
        hour_up_next   = 1'b0;
        sec_down_next  = 1'b0;
        min_down_next  = 1'b0;
        hour_down_next = 1'b0;

        if (i_sec_up) begin
            n_state = SELECT_SEC;
            sec_up_next = 1'b1;
        end else if (i_min_up) begin
            n_state = SELECT_MIN;
            min_up_next = 1'b1;
        end else if (i_hour_up) begin
            n_state  = SELECT_HOUR;
            hour_up_next = 1'b1;
        end else if (i_minus) begin
            case (c_state)
                SELECT_SEC: begin
                    sec_down_next = 1'b1;
                end
                SELECT_MIN: begin
                    min_down_next = 1'b1;
                end
                SELECT_HOUR: begin
                    hour_down_next = 1'b1;
                end
                default: begin
                    sec_down_next = 1'b1;
                end
            endcase
        end
    end

endmodule
