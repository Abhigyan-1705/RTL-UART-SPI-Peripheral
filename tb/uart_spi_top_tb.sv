`timescale 1ns/1ps

module uart_spi_top_tb;

    logic clk;
    logic rst_n;

    // UART
    logic uart_rx;
    logic uart_tx;

    // SPI
    logic spi_mosi;
    logic spi_miso;
    logic spi_sclk;
    logic spi_cs_n;

    localparam integer CLK_FREQ_HZ = 100_000_000;
    localparam integer BAUD_RATE   = 115200;
    localparam integer SPI_FREQ_HZ = 1_000_000;

    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;

    // ---------------------------------------------------------
    // DUT
    // ---------------------------------------------------------

    uart_spi_top #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE  (BAUD_RATE),
        .SPI_FREQ_HZ(SPI_FREQ_HZ)
    ) dut (
        .clk     (clk),
        .rst_n   (rst_n),

        .uart_rx (uart_rx),
        .uart_tx (uart_tx),

        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n)
    );

    // ---------------------------------------------------------
    // 100 MHz clock
    // ---------------------------------------------------------

    always #5 clk = ~clk;


    // ---------------------------------------------------------
    // UART transmit task
    // Sends one byte into FPGA UART RX
    // ---------------------------------------------------------

    task send_uart_byte(input [7:0] data);
        integer i;
        begin

            // Start bit
            uart_rx = 1'b0;
            repeat (CLKS_PER_BIT) @(posedge clk);

            // Data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end

            // Stop bit
            uart_rx = 1'b1;
            repeat (CLKS_PER_BIT) @(posedge clk);

        end
    endtask


    // ---------------------------------------------------------
    // SPI slave model
    //
    // FPGA sends 96.
    // SPI slave returns 3A.
    // Mode 0, MSB first.
    // ---------------------------------------------------------

    reg [7:0] spi_slave_data;
    integer spi_bit;

    initial begin
        spi_slave_data = 8'h3A;
        spi_bit        = 7;
        spi_miso       = 1'b0;
    end

    // Load first MSB when chip select becomes active
    always @(negedge spi_cs_n) begin
        spi_bit = 7;
        spi_miso = spi_slave_data[7];
    end

    // Mode 0:
    // Slave changes MISO on falling edge.
    // Master samples MISO on rising edge.
    always @(negedge spi_sclk) begin

        if (!spi_cs_n) begin

            if (spi_bit > 0) begin
                spi_bit = spi_bit - 1;
                spi_miso = spi_slave_data[spi_bit];
            end

        end

    end


    // ---------------------------------------------------------
    // Main test
    // ---------------------------------------------------------

    initial begin

        clk     = 1'b0;
        rst_n   = 1'b0;
        uart_rx = 1'b1;       // UART idle

        // Reset
        #100;

        rst_n = 1'b1;

        repeat (20) @(posedge clk);

        // -----------------------------------------------------
        // Send command 01
        // -----------------------------------------------------

        $display("--------------------------------------");
        $display("Sending UART command: 01");
        $display("--------------------------------------");

        send_uart_byte(8'h01);

        // -----------------------------------------------------
        // Send SPI data 96
        // -----------------------------------------------------

        $display("Sending UART data: 96");

        send_uart_byte(8'h96);

        // -----------------------------------------------------
        // Wait for SPI transaction
        // -----------------------------------------------------

        wait (spi_cs_n == 1'b0);

        $display("SPI transaction started");

        // Wait until SPI transaction finishes
        wait (spi_cs_n == 1'b1);

        $display("SPI transaction completed");

        // -----------------------------------------------------
        // Wait for UART response
        // -----------------------------------------------------

        // Allow enough time for UART TX response
        #100000;

        $display("--------------------------------------");
        $display("END-TO-END TEST COMPLETE");
        $display("--------------------------------------");

        $finish;

    end


    // ---------------------------------------------------------
    // Monitor SPI MOSI/MISO
    // ---------------------------------------------------------

    always @(posedge spi_sclk) begin

        if (!spi_cs_n) begin
            $display(
                "SPI sample: MOSI=%b MISO=%b time=%0t",
                spi_mosi,
                spi_miso,
                $time
            );
        end

    end

endmodule