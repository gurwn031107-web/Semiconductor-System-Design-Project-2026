`timescale 1ns / 1ps

// Four-slave APB master for aligned 32-bit word transfers.
// 0: RAM, 1: GPIO, 2: FND, 3: UART. UART peripheral is external.
// Unmapped addresses do not complete; reset is required to recover.
// No byte strobes or slave-error reporting in this basic version.
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
    output wire         PSEL0,
    output wire         PSEL1,
    output wire         PSEL2,
    output wire         PSEL3,
    output logic        PENABLE,
    input  logic [31:0] PRDATA0,
    input  logic [31:0] PRDATA1,
    input  logic [31:0] PRDATA2,
    input  logic [31:0] PRDATA3,
    input  logic        PREADY0,
    input  logic        PREADY1,
    input  logic        PREADY2,
    input  logic        PREADY3
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_e;

    logic decode_en;
    wire [31:0] selected_rdata;
    wire selected_ready;

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
        decode_en   = 1'b0;
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
                decode_en = 1'b1;
                n_state = ACCESS;
            end

            ACCESS: begin
                decode_en = 1'b1;
                PENABLE = 1'b1;
                if (selected_ready) begin
                    ready = 1'b1;
                    if (!PWRITE)
                        bus_rdata = selected_rdata;
                    n_state = IDLE;
                end
            end

            default: begin
                n_state = IDLE;
            end
        endcase

        if (!rst_n) begin
            decode_en = 1'b0;
            PENABLE   = 1'b0;
            ready     = 1'b0;
            bus_rdata = 32'd0;
        end
    end

    addr_decoder U_ADDR_DECODER (
        .en(decode_en), .addr(PADDR),
        .psel0(PSEL0), .psel1(PSEL1), .psel2(PSEL2), .psel3(PSEL3)
    );

    apb_mux U_APB_MUX (
        .sel({PSEL3, PSEL2, PSEL1, PSEL0}),
        .PRDATA0(PRDATA0), .PRDATA1(PRDATA1),
        .PRDATA2(PRDATA2), .PRDATA3(PRDATA3),
        .PREADY0(PREADY0), .PREADY1(PREADY1),
        .PREADY2(PREADY2), .PREADY3(PREADY3),
        .Rdata(selected_rdata), .Ready(selected_ready)
    );
endmodule


module addr_decoder (
    input logic en,
    input logic [31:0] addr,
    output logic psel0, psel1, psel2, psel3
);
    always_comb begin
        {psel3, psel2, psel1, psel0} = 4'b0000;
        if (en) begin
            // Exact 4-KiB windows. Slaves decode register offsets separately.
            case (addr[31:12])
                20'h10000: psel0 = 1'b1; // RAM:  0x1000_0000
                20'h20000: psel1 = 1'b1; // GPIO: 0x2000_0000
                20'h20001: psel2 = 1'b1; // FND:  0x2000_1000
                20'h20002: psel3 = 1'b1; // UART: 0x2000_2000
                default: ;
            endcase
        end
    end
endmodule

module apb_mux (
    input logic [3:0] sel,
    input logic [31:0] PRDATA0, PRDATA1, PRDATA2, PRDATA3,
    input logic PREADY0, PREADY1, PREADY2, PREADY3,
    output logic [31:0] Rdata,
    output logic Ready
);
    always_comb begin
        Rdata = 32'd0;
        Ready = 1'b0;
        case (sel)
            4'b0001: begin Rdata = PRDATA0; Ready = PREADY0; end
            4'b0010: begin Rdata = PRDATA1; Ready = PREADY1; end
            4'b0100: begin Rdata = PRDATA2; Ready = PREADY2; end
            4'b1000: begin Rdata = PRDATA3; Ready = PREADY3; end
            default: ;
        endcase
    end
endmodule
