`timescale 1ns / 1ps

module tb_dht11_controller ();

    reg clk;
    reg reset;
    reg start;
    reg dht11_sensor_io, dht11_sensor_io_control;
    reg [39:0] sensor_data;

    wire [15:0] humidity;
    wire [15:0] temperature;
    wire done;
    wire valid;
    wire dht11_io;

    assign dht11_io = (dht11_sensor_io_control) ? dht11_sensor_io : 1'bz;

    dht11_controller dut (
        .clk        (clk),
        .reset      (reset),
        .start      (start),
        .humidity   (humidity),
        .temperature(temperature),
        .done       (done),
        .valid      (valid),
        .dht11_io   (dht11_io)
    );

    always #5 clk = ~clk;

    integer i = 0;

    initial begin
        clk = 0;
        reset = 1;
        start = 0;
        dht11_sensor_io = 1;
        dht11_sensor_io_control = 0;
        #10;
        reset = 0;

        #10;
        start = 1;
        #(19_000_000);  //19msec
        #(30_000);  //30usec
        dht11_sensor_io = 1'b0;
        dht11_sensor_io_control = 1;
        #(80_000);
        dht11_sensor_io = 1'b1;
        #(80_000);
        //data
        sensor_data = 40'h19_00_19_00_32;
        for (i = 0; i < 40; i = i + 1) begin
            //50usec low
            dht11_sensor_io = 1'b0;
            #(50_000);
            dht11_sensor_io = 1'b1;
            if (sensor_data[39-i]) begin
                #(70_000);
            end else begin
                #(27_000);
            end
        end
        
        dht11_sensor_io = 1'b0;
        #(50_000);
        dht11_sensor_io = 1'b1; 
       
        //40usec
        dht11_sensor_io_control = 1'b0;
        #(1000);
        $stop;
    end

endmodule
