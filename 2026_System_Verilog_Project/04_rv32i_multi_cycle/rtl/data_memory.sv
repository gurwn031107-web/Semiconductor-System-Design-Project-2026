
module data_mem(
    input logic clk,
    input logic dwe,
    input logic [2:0] itype,
    input logic [31:0] daddr,
    input logic [31:0] dwdata,
    output logic [31:0] drdata
);

    logic [31:0] dmem[0:127];

    always_ff @(posedge clk) begin
            if (dwe) begin
                case(itype)
                    3'b000: begin // SB
              case (daddr[1:0])
                  2'b00: dmem[daddr[31:2]][7:0] <= dwdata[7:0];
                  2'b01: dmem[daddr[31:2]][15:8] <= dwdata[7:0];
                  2'b10: dmem[daddr[31:2]][23:16] <= dwdata[7:0];
                  2'b11: dmem[daddr[31:2]][31:24] <= dwdata[7:0];
              endcase
          end

          3'b001: begin // SH
              case (daddr[1])
                  1'b0: dmem[daddr[31:2]][15:0] <= dwdata[15:0];
                                    1'b1: dmem[daddr[31:2]][31:16] <= dwdata[15:0];
              endcase
            end

                    3'b010: begin // SW
                        dmem[daddr[31:2]] <= dwdata;
                    end

                    default: dmem[daddr[31:2]] <= dmem[daddr[31:2]];
                endcase
            end
    end


    always_comb begin
        case (itype)
            3'b000: begin // LB
                case (daddr[1:0])
                    2'b00: drdata = {{24{dmem[daddr[31:2]][7]}}, dmem[daddr[31:2]][7:0]};
                    2'b01: drdata = {{24{dmem[daddr[31:2]][15]}}, dmem[daddr[31:2]][15:8]};
                    2'b10: drdata = {{24{dmem[daddr[31:2]][23]}}, dmem[daddr[31:2]][23:16]};
                    2'b11: drdata = {{24{dmem[daddr[31:2]][31]}}, dmem[daddr[31:2]][31:24]};
                endcase
            end

            3'b001: begin // LH
                case (daddr[1])
                    1'b0: drdata = {{16{dmem[daddr[31:2]][15]}}, dmem[daddr[31:2]][15:0]};
                    1'b1: drdata = {{16{dmem[daddr[31:2]][31]}}, dmem[daddr[31:2]][31:16]};
                endcase
            end

            3'b010: drdata = dmem[daddr[31:2]]; // LW

            3'b100: begin // LBU
                case (daddr[1:0])
                    2'b00: drdata = {24'b0, dmem[daddr[31:2]][7:0]};
                    2'b01: drdata = {24'b0, dmem[daddr[31:2]][15:8]};
                    2'b10: drdata = {24'b0, dmem[daddr[31:2]][23:16]};
                    2'b11: drdata = {24'b0, dmem[daddr[31:2]][31:24]};
                endcase
            end

            3'b101: begin // LHU
                case (daddr[1])
                    1'b0: drdata = {16'b0, dmem[daddr[31:2]][15:0]};
                    1'b1: drdata = {16'b0, dmem[daddr[31:2]][31:16]};
                endcase
            end

            default: drdata = 32'b0;
        endcase
    end


endmodule
