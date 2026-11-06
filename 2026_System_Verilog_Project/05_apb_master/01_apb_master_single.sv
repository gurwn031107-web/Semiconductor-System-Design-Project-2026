`timescale 1ns / 1ps

// Single-slave APB master for aligned 32-bit word transfers.
// CPU: present transfer and request fields in IDLE. Sample ready and
// bus_rdata at the rising edge, then deassert transfer to avoid reissue.
module APB_master (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [31:0] bus_addr,
    input  logic [31:0] bus_wdata,
    input  logic        transfer,
    input  logic        bus_we,
    output logic [31:0] bus_rdata,
    output logic        ready,

    output logic [31:0] PADDR,
    output logic [31:0] PWDATA,
    output logic        PWRITE,
    output logic        PSEL,
    output logic        PENABLE,
    input  logic [31:0] PRDATA,
    input  logic        PREADY
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_e;

    apb_state_e c_state, n_state;
    logic [31:0] PADDR_next;
    logic [31:0] PWDATA_next;
    logic        PWRITE_next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_state <= IDLE;
            PADDR   <= 32'd0;
            PWDATA  <= 32'd0;
            PWRITE  <= 1'b0;
        end else begin
            c_state <= n_state;
            PADDR   <= PADDR_next;
            PWDATA  <= PWDATA_next;
            PWRITE  <= PWRITE_next;
        end
    end

    always_comb begin
        n_state     = c_state;
        PADDR_next  = PADDR;
        PWDATA_next = PWDATA;
        PWRITE_next = PWRITE;
        PSEL        = 1'b0;
        PENABLE     = 1'b0;
        ready       = 1'b0;
        bus_rdata   = 32'd0;

        case (c_state)
            IDLE: begin
                if (transfer) begin
                    PADDR_next  = bus_addr;
                    PWDATA_next = bus_wdata;
                    PWRITE_next = bus_we;
                    n_state     = SETUP;
                end
            end

            SETUP: begin
                PSEL    = 1'b1;
                n_state = ACCESS;
            end

            ACCESS: begin
                PSEL    = 1'b1;
                PENABLE = 1'b1;
                if (PREADY) begin
                    ready = 1'b1;
                    if (!PWRITE)
                        bus_rdata = PRDATA;
                    n_state = IDLE;
                end
            end

            default: begin
                n_state = IDLE;
            end
        endcase

        if (!rst_n) begin
            PSEL      = 1'b0;
            PENABLE   = 1'b0;
            ready     = 1'b0;
            bus_rdata = 32'd0;
        end
    end

endmodule
