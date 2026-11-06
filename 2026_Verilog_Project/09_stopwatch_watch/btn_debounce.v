`timescale 1ns / 1ps

module btn_debounce(
    input clk,
    input reset,
    input i_btn,
    output o_btn
);

    reg [7:0] q_reg;
    wire debounce;
    reg edge_reg;

    //assign o_btn = q_reg[7];

    reg o_1mhz;
    reg [$clog2(50) - 1 : 0] counter_reg;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            o_1mhz <= 0;
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
            if(counter_reg == (50 -1)) begin
                o_1mhz <= ~o_1mhz;
            end
        end
    end



    always @(posedge o_1mhz, posedge reset) begin
        if(reset) begin
            q_reg <= 8'h00;
        end
        else begin
        //q_reg <= {q_reg[6:0], i_btn};
            q_reg <= {i_btn, q_reg[7:1]};
        end

    end

    assign debounce = &q_reg;


    always @(posedge clk, posedge reset) begin
        if(reset)
            edge_reg <= 1'b0;
        else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = debounce & (~edge_reg);

endmodule
