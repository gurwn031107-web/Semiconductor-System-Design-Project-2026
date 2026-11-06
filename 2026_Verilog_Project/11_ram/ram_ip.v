`timescale 1ns / 1ps

module ram_ip (
    input        clk,
    input  [5:0] addr,
    input  [7:0] w_data,
    input        wr,
    output reg [7:0] r_data
);

    reg [7:0] ram [0:63];


    always @(posedge clk) begin
        if (wr) begin 
            ram[addr] <= w_data;
        end
        // SL output
        else begin
            r_data <= ram[addr];
        end
    end

    // CL output
    //assign r_data = (!wr) ? ram[addr] : 8'hz;
    //assign r_data = ram[addr];

endmodule
