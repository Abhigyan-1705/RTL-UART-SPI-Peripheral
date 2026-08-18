`timescale 1ns/1ps

module uart_tx_tb;

    logic clk;
    logic rst_n;

    logic [7:0] data_in;
    logic tx_start;
    logic baud_tick;

    logic tx;
    logic tx_busy;

    // DUT
    uart_tx dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .tx_start(tx_start),
        .baud_tick(baud_tick),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // Generate baud tick
    // 868 clock cycles ? 115200 baud
    initial begin
        baud_tick = 1'b0;

        forever begin
            repeat (868) @(posedge clk);
            baud_tick = 1'b1;

            @(posedge clk);
            baud_tick = 1'b0;
        end
    end

    // Test
    initial begin

        clk      = 1'b0;
        rst_n    = 1'b0;
        data_in  = 8'h00;
        tx_start = 1'b0;

        // Reset
        #100;

        rst_n = 1'b1;

        // Give one clock cycle after reset
        @(posedge clk);

        // Send A5
        data_in  = 8'hA5;
        tx_start = 1'b1;

        @(posedge clk);

        tx_start = 1'b0;

        // Wait for transmission
        #1000000;

        $finish;
    end

endmodule