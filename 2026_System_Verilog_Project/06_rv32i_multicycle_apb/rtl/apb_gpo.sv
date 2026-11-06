module apb_gpo (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PSEL,
    input  logic        PENABLE,
    output logic [7:0]  GPO_OUT,
    output logic        PREADY,
    output logic [31:0] PRDATA
);
    localparam GPO_CTR_ADDR = 8'h00, GPO_ODR_ADDR = 8'h04;
    logic [7:0] GPO_CTR;      // 000h
    logic [7:0] GPO_ODR;      // 004h

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            GPO_CTR <= 8'h0;
            GPO_ODR <= 8'h0;
        end else begin
            if (PREADY & PWRITE) begin
                if (PADDR[7:0] == GPO_CTR_ADDR)
                    GPO_CTR <= PWDATA[7:0];
                if (PADDR[7:0] == GPO_ODR_ADDR)
                    GPO_ODR <= PWDATA[7:0];
            end
        end
    end

    assign PRDATA = (PADDR[7:0] == GPO_CTR_ADDR) ? {24'h0, GPO_CTR} :
                    (PADDR[7:0] == GPO_ODR_ADDR) ? {24'h0, GPO_ODR} : 32'hx;

    genvar i;
    generate
        for (i = 0; i < 8; i++) begin
            assign GPO_OUT[i] = GPO_CTR[i] ? GPO_ODR[i] : 1'bz;
        end
    endgenerate
endmodule

