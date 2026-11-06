    `timescale 1ns / 1ps



    module tb_uart ();
        // (system freq / baud rate) *
        parameter BAUD_TICK = (100_000_000 / 9600) * 10;

        reg           clk;
        reg           reset;
        reg           tx_start;
        reg     [7:0] tx_data;
        reg           rx;
        wire    [7:0] rx_data;
        wire          rx_done;
        wire          tx_busy;
        wire          tx_done;
        wire          tx;

        integer       i = 0;

        uart_controller dut (
            .clk     (clk),
            .reset   (reset),
            .tx      (tx),
            .tx_start(tx_start),
            .tx_data (tx_data),
            .rx      (rx),
            .rx_data (rx_data),
            .rx_done (rx_done),
            .tx_busy (tx_busy),
            .tx_done (tx_done)

        );

        //freq 100MHz
        always #5 clk = ~clk;

        // task : uart tx start
        task UART_TX_START_TASK(input [7:0] data);
            begin
                //uart tx
                @(negedge clk);  // wait nega clk
                tx_start = 1;
                tx_data  = data;
                @(negedge clk);  // wait nega clk
                tx_start = 0;
                // #(BAUD_TICK * 10);   //time control
                //event control
                wait (dut.U_UART_TX.tx_done);
            end
        endtask

        task SENDER_FOR_UART_RX(input [7:0] send_data);
            begin
                rx = 0;
                #(BAUD_TICK);
                //data
                for (i = 0; i < 8; i = i + 1) begin 
                    rx = send_data[i];
                    #(BAUD_TICK);
                end
                rx = 1;
                #(BAUD_TICK);
            end
        endtask

        initial begin
            clk      = 0;
            reset    = 1;
            tx_start = 0;
            tx_data  = 0;
            rx       = 1;
            #10;
            reset = 0;
            #10;
            // sim for UART TX
            UART_TX_START_TASK(8'h30);
            UART_TX_START_TASK(8'h31);
            // sim for UART RX
            SENDER_FOR_UART_RX(8'h32);
            SENDER_FOR_UART_RX(8'h33);

            #100;
            $stop;
        end

    endmodule
