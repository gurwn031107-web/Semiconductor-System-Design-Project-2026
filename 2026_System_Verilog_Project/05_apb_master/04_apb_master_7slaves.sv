`timescale 1ns / 1ps
// Seven-target APB requester. Aligned 32-bit accesses only; no PSTRB/PSLVERR.
// Keep transfer asserted until the rising edge with ready, then deassert it.
// Unmapped addresses stall (no error interface); reset to recover.
module APB_master (
    input logic clk,
    input logic rst_n,
    input logic [31:0] bus_addr,
    input logic [31:0] bus_wdata,
    input logic transfer,
    input logic bus_we,
    output logic [31:0] bus_rdata,
    output logic ready,
    input logic [31:0] PRDATA0,
    input logic [31:0] PRDATA1,
    input logic [31:0] PRDATA2,
    input logic [31:0] PRDATA3,
    input logic [31:0] PRDATA4,
    input logic [31:0] PRDATA5,
    input logic [31:0] PRDATA6,
    input logic PREADY0,
    input logic PREADY1,
    input logic PREADY2,
    input logic PREADY3,
    input logic PREADY4,
    input logic PREADY5,
    input logic PREADY6,
    output logic [31:0] PADDR,
    output logic [31:0] PWDATA,
    output logic PWRITE,
    output logic PSEL0,
    output logic PSEL1,
    output logic PSEL2,
    output logic PSEL3,
    output logic PSEL4,
    output logic PSEL5,
    output logic PSEL6,
    output logic PENABLE
);
    typedef enum logic [1:0] {IDLE, SETUP, ACCESS} apb_state_e;
    apb_state_e c_state, n_state;
    logic decode_en;
    logic [2:0] mux_sel;
    logic [31:0] mux_rdata;
    logic mux_ready;
    logic [31:0] PADDR_next, PWDATA_next;
    logic PWRITE_next;

    address_decoder U_APB_DECODER (
        .enable(decode_en),
        .mux_sel(mux_sel),
        .*
    );

    apb_mux U_APB_MUX (
        .sel(mux_sel),
        .bus_rdata(mux_rdata),
        .ready(mux_ready),
        .*
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_state <= IDLE;
            PADDR <= 32'd0;
            PWDATA <= 32'd0;
            PWRITE <= 1'b0;
        end else begin
            c_state <= n_state;
            PADDR <= PADDR_next;
            PWDATA <= PWDATA_next;
            PWRITE <= PWRITE_next;
        end
    end

    always_comb begin
        n_state = c_state;
        PADDR_next = PADDR;
        PWDATA_next = PWDATA;
        PWRITE_next = PWRITE;
        decode_en = 1'b0;
        PENABLE = 1'b0;
        ready = 1'b0;
        bus_rdata = 32'd0;
        case (c_state)
            IDLE: begin
                if (transfer) begin
                    PADDR_next = bus_addr;
                    PWDATA_next = bus_wdata;
                    PWRITE_next = bus_we;
                    n_state = SETUP;
                end
            end
            SETUP: begin
                decode_en = 1'b1;
                n_state = ACCESS;
            end
            ACCESS: begin
                decode_en = 1'b1;
                PENABLE = 1'b1;
                ready = mux_ready;
                if (!PWRITE) bus_rdata = mux_rdata;
                if (mux_ready) n_state = IDLE;
            end
            default: n_state = IDLE;
        endcase
        if (!rst_n) begin
            decode_en = 1'b0;
            PENABLE = 1'b0;
            ready = 1'b0;
            bus_rdata = 32'd0;
        end
    end
endmodule

module address_decoder (
    input logic enable,
    output logic [2:0] mux_sel,
    input logic [31:0] PADDR,
    output logic PSEL0,
    output logic PSEL1,
    output logic PSEL2,
    output logic PSEL3,
    output logic PSEL4,
    output logic PSEL5,
    output logic PSEL6
);
    always_comb begin
        {PSEL6, PSEL5, PSEL4, PSEL3, PSEL2, PSEL1, PSEL0} = 7'b0;
        mux_sel = 3'b111; // No target selected; never accidentally select RAM.
        if (enable) begin
            // Preserve the supplied partial-address decode.
            // Unchecked address bits create aliases; this is not a full decode.
            case (PADDR[31:28])
                4'h1: begin
                    PSEL0 = 1'b1;
                    mux_sel = 3'd0;
                end
                4'h2: begin
                    case (PADDR[11:8])
                        4'h0: begin PSEL1 = 1'b1; mux_sel = 3'd1; end
                        4'h1: begin PSEL2 = 1'b1; mux_sel = 3'd2; end
                        4'h2: begin PSEL3 = 1'b1; mux_sel = 3'd3; end
                        4'h3: begin PSEL4 = 1'b1; mux_sel = 3'd4; end
                        4'h4: begin PSEL5 = 1'b1; mux_sel = 3'd5; end
                        4'h5: begin PSEL6 = 1'b1; mux_sel = 3'd6; end
                        default: ;
                    endcase
                end
                default: ;
            endcase
        end
    end
endmodule

module apb_mux (
    input logic [2:0] sel,
    input logic [31:0] PRDATA0,
    input logic [31:0] PRDATA1,
    input logic [31:0] PRDATA2,
    input logic [31:0] PRDATA3,
    input logic [31:0] PRDATA4,
    input logic [31:0] PRDATA5,
    input logic [31:0] PRDATA6,
    input logic PREADY0,
    input logic PREADY1,
    input logic PREADY2,
    input logic PREADY3,
    input logic PREADY4,
    input logic PREADY5,
    input logic PREADY6,
    output logic [31:0] bus_rdata,
    output logic ready
);
    always_comb begin
        bus_rdata = 32'd0;
        ready = 1'b0;
        case (sel)
            3'd0: begin bus_rdata = PRDATA0; ready = PREADY0; end
            3'd1: begin bus_rdata = PRDATA1; ready = PREADY1; end
            3'd2: begin bus_rdata = PRDATA2; ready = PREADY2; end
            3'd3: begin bus_rdata = PRDATA3; ready = PREADY3; end
            3'd4: begin bus_rdata = PRDATA4; ready = PREADY4; end
            3'd5: begin bus_rdata = PRDATA5; ready = PREADY5; end
            3'd6: begin bus_rdata = PRDATA6; ready = PREADY6; end
            default: ;
        endcase
    end
endmodule
