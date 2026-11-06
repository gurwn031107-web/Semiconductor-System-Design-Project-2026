// 32-bit APB master + five-target decoder / response mux.
// CPU contract: assert transfer with a request while idle, then hold it
// until ready. Sample bus_rdata / bus_error on the rising edge with ready.
// Deassert transfer after that edge; a later assertion starts a new request.
// No byte strobes: this initial interface supports aligned LW / SW only.
module apb_master #(
    parameter logic [31:0] RAM_BASE  = 32'h0000_0000,
    parameter logic [31:0] GPO_BASE  = 32'h1000_0000,
    parameter logic [31:0] GPI_BASE  = 32'h1000_1000,
    parameter logic [31:0] GPIO_BASE = 32'h1000_2000,
    parameter logic [31:0] FND_BASE  = 32'h1000_3000,
    // Each default window is 4 KiB. Bases must be aligned to this mask,
    // and windows must not overlap. Slave RAM must check its own depth.
    parameter logic [31:0] ADDR_MASK = 32'hffff_f000
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        transfer,
    input  logic [31:0] bus_addr,
    input  logic [31:0] bus_wdata,
    input  logic        bus_we,
    output logic [31:0] bus_rdata,
    output logic        ready,
    output logic        bus_error,

    output logic [31:0] PADDR,
    output logic [31:0] PWDATA,
    output logic        PWRITE,
    output logic        PENABLE,
    output logic [4:0]  PSEL,
    // Index 0=RAM, 1=GPO, 2=GPI, 3=GPIO, 4=FND.
    input  logic [31:0] PRDATA [0:4],
    input  logic [4:0]  PREADY,
    input  logic [4:0]  PSLVERR
);
    typedef enum logic [1:0] {IDLE, SETUP, ACCESS} state_t;
    state_t state;
    logic [4:0] select_q, decoded_select;
    logic invalid_q, selected_ready, selected_error;
    logic [31:0] selected_rdata;

    always_comb begin
        decoded_select = '0;
        // Priority decode; configure non-overlapping windows.
        if      ((bus_addr & ADDR_MASK) == RAM_BASE)  decoded_select[0] = 1'b1;
        else if ((bus_addr & ADDR_MASK) == GPO_BASE)  decoded_select[1] = 1'b1;
        else if ((bus_addr & ADDR_MASK) == GPI_BASE)  decoded_select[2] = 1'b1;
        else if ((bus_addr & ADDR_MASK) == GPIO_BASE) decoded_select[3] = 1'b1;
        else if ((bus_addr & ADDR_MASK) == FND_BASE)  decoded_select[4] = 1'b1;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state     <= IDLE;
            PADDR     <= '0;
            PWDATA    <= '0;
            PWRITE    <= 1'b0;
            select_q  <= '0;
            invalid_q <= 1'b0;
        end else begin
            case (state)
                IDLE: if (transfer) begin
                    PADDR     <= bus_addr;
                    PWDATA    <= bus_wdata;
                    PWRITE    <= bus_we;
                    invalid_q <= (decoded_select == 5'b0) || (bus_addr[1:0] != 2'b0);
                    select_q  <= (bus_addr[1:0] == 2'b0) ? decoded_select : 5'b0;
                    state     <= SETUP;
                end
                SETUP: state <= ACCESS;
                ACCESS: if (ready) state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end

    always_comb begin
        selected_ready = 1'b0;
        selected_error = 1'b0;
        selected_rdata = '0;
        for (int i = 0; i < 5; i++) begin
            if (select_q[i]) begin
                selected_ready = PREADY[i];
                selected_error = PSLVERR[i];
                selected_rdata = PRDATA[i];
            end
        end

        PSEL      = '0;
        PENABLE   = 1'b0;
        ready     = 1'b0;
        bus_error = 1'b0;
        bus_rdata = '0;
        if (rst_n) begin
            if (state == SETUP || state == ACCESS) PSEL = select_q;
            if (state == ACCESS) begin
                PENABLE = !invalid_q;
                ready = invalid_q || selected_ready;
                bus_error = ready && (invalid_q || selected_error);
                // Combinational response: CPU captures data on completion edge.
                if (ready && !bus_error && !PWRITE) bus_rdata = selected_rdata;
            end
        end
    end
endmodule
