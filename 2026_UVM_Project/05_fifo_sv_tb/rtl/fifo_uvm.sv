`timescale 1ns / 1ps


module fifo #(
    parameter WIDTH = 4 // 4bit -> depth 16
) (
    input        clk,
    input        reset,
    input        push,
    input        pop,
    input  [7:0] w_data,
    output [7:0] r_data,
    output       full,
    output       empty
);

    wire [WIDTH - 1:0] w_wptr, w_rptr;

    register_file #(
        .WIDTH(WIDTH)
    ) U_REG_FILE (
        .clk   (clk),
        .w_addr(w_wptr),
        .r_addr(w_rptr),
        .w_data(w_data),
        .we    ((~reset & ~full & push)),
        .r_data(r_data)
    );

    control_unit #(
        .WIDTH(WIDTH)
    ) U_CONTROL_UNIT (
        .clk  (clk),
        .reset(reset),
        .push (push),
        .pop  (pop),
        .wptr (w_wptr),
        .rptr (w_rptr),
        .full (full),
        .empty(empty)
    );

endmodule

module register_file #(
    parameter WIDTH = 4
) (
    input                clk,
    input  [WIDTH - 1:0] w_addr,
    input  [WIDTH - 1:0] r_addr,
    input  [        7:0] w_data,
    input                we,
    output [        7:0] r_data
);

    parameter DEPTH = 2 ** WIDTH;

    reg [7:0] register_file[0:DEPTH - 1];

    always @(posedge clk) begin
        if (we) begin
            register_file[w_addr] <= w_data;
        end
    end

    assign r_data = register_file[r_addr];

    // radata : CL output
endmodule

module control_unit #(
    parameter WIDTH = 4
) (
    input                clk,
    input                reset,
    input                push,
    input                pop,
    output [WIDTH - 1:0] wptr,
    output [WIDTH - 1:0] rptr,
    output               full,
    output               empty
);

    parameter DEPTH = 2 ** WIDTH;
    reg [WIDTH - 1:0] wptr_reg;
    reg [WIDTH - 1:0] wptr_next;
    reg [WIDTH - 1:0] rptr_reg;
    reg [WIDTH - 1:0] rptr_next;
    reg full_reg;
    reg full_next;
    reg empty_reg;
    reg empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    // next CL
    always @(*) begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            push, pop
        })
            2'b00: begin
                // init
            end

            2'b01: begin
                //pop only
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1'b1;
                    full_next = 1'b0;
                end
                if (wptr_reg == rptr_next) empty_next = 1'b1;
            end

            2'b10: begin
                // push only
                if (!full_reg) begin
                    wptr_next  = wptr_reg + 1'b1;
                    empty_next = 1'b0;
                end
                if (wptr_next == rptr_reg) full_next = 1'b1;
            end

            2'b11: begin
                //push_pop
                if (full_reg) begin
                    rptr_next = rptr_reg + 1'b1;
                    full_next = 1'b0;
                end else if (empty) begin
                    wptr_next  = wptr_reg + 1'b1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1'b1;
                    rptr_next = rptr_reg + 1'b1;
                end
            end
        endcase
    end

endmodule

