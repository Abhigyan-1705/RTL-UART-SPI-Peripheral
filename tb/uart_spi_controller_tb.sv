`timescale 1ns/1ps

module uart_spi_controller_tb;

    logic clk;
    logic rst_n;

    // UART RX interface
    logic [7:0] uart_rx_data;
    logic       uart_rx_valid;

    // UART TX interface
    logic [7:0] uart_tx_data;
    logic       uart_tx_start;
    logic       uart_tx_busy;

    // SPI interface
    logic [7:0] spi_tx_data;
    logic       spi_start;
    logic [7:0] spi_rx_data;
    logic       spi_done;

    // DUT
    uart_spi_controller dut (
        .clk           (clk),
        .rst_n         (rst_n),

        .uart_rx_data  (uart_rx_data),
        .uart_rx_valid (uart_rx_valid),

        .uart_tx_data  (uart_tx_data),
        .uart_tx_start (uart_tx_start),
        .uart_tx_busy  (uart_tx_busy),

        .spi_tx_data   (spi_tx_data),
        .spi_start     (spi_start),
        .spi_rx_data   (spi_rx_data),
        .spi_done      (spi_done)
    );

    // 100 MHz clock
    always #5 clk = ~clk;


    // ---------------------------------------------------------
    // Test sequence
    // ---------------------------------------------------------
    initial begin

        clk = 1'b0;
        rst_n = 1'b0;

        uart_rx_data  = 8'h00;
        uart_rx_valid = 1'b0;

        uart_tx_busy = 1'b0;

        spi_rx_data = 8'h00;
        spi_done    = 1'b0;

        // Reset
        #100;
        rst_n = 1'b1;

        // -----------------------------------------------------
        // Send command = 01
        // -----------------------------------------------------
        @(negedge clk);
        uart_rx_data  = 8'h01;
        uart_rx_valid = 1'b1;

        @(negedge clk);
        uart_rx_valid = 1'b0;

        // -----------------------------------------------------
        // Send SPI data = 96
        // -----------------------------------------------------
        @(negedge clk);
        uart_rx_data  = 8'h96;
        uart_rx_valid = 1'b1;

        @(negedge clk);
        uart_rx_valid = 1'b0;

        // -----------------------------------------------------
        // Wait for controller to request SPI
        // -----------------------------------------------------
        wait (spi_start == 1'b1);

        if (spi_tx_data == 8'h96)
            $display("PASS: SPI TX data = 96");
        else
            $display("FAIL: SPI TX data = %h", spi_tx_data);

        // -----------------------------------------------------
        // Simulate SPI slave response = 3A
        // -----------------------------------------------------
        @(negedge clk);

        spi_rx_data = 8'h3A;
        spi_done    = 1'b1;

        @(negedge clk);
        spi_done    = 1'b0;

        // -----------------------------------------------------
        // Wait for UART TX request
        // -----------------------------------------------------
        wait (uart_tx_start == 1'b1);

        if (uart_tx_data == 8'h3A)
            $display("PASS: UART TX data = 3A");
        else
            $display("FAIL: UART TX data = %h", uart_tx_data);

        // Simulate UART transmitter becoming busy
        @(negedge clk);
        uart_tx_busy = 1'b1;

        @(negedge clk);
        uart_tx_busy = 1'b0;

        // Allow controller to return to IDLE
        repeat (5) @(posedge clk);

        $display("--------------------------------------");
        $display("UART-SPI CONTROLLER TEST COMPLETE");
        $display("--------------------------------------");

        $finish;

    end

endmodule