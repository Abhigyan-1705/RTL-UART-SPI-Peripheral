module uart_spi_top #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE   = 115200,
    parameter integer SPI_FREQ_HZ = 1_000_000
)(
    input  logic       clk,
    input  logic       rst_n,

    // UART interface
    input  logic       uart_rx,
    output logic       uart_tx,

    // SPI interface
    output logic       spi_mosi,
    input  logic       spi_miso,
    output logic       spi_sclk,
    output logic       spi_cs_n
);

    // ---------------------------------------------------------
    // UART baud generator
    // ---------------------------------------------------------

    logic baud_tick;

    baud_generator #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE  (BAUD_RATE)
    ) u_baud_generator (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_tick (baud_tick)
    );


    // ---------------------------------------------------------
    // UART RX
    // ---------------------------------------------------------

    logic [7:0] uart_rx_data;
    logic       uart_rx_valid;

    uart_rx #(
        .CLKS_PER_BIT(CLK_FREQ_HZ / BAUD_RATE)
    ) u_uart_rx (
        .clk      (clk),
        .rst_n    (rst_n),
        .rx       (uart_rx),
        .rx_data  (uart_rx_data),
        .rx_valid (uart_rx_valid)
    );


    // ---------------------------------------------------------
    // UART TX
    // ---------------------------------------------------------

    logic [7:0] uart_tx_data;
    logic       uart_tx_start;
    logic       uart_tx_busy;

    uart_tx u_uart_tx (
        .clk       (clk),
        .rst_n     (rst_n),
        .data_in   (uart_tx_data),
        .tx_start  (uart_tx_start),
        .baud_tick (baud_tick),
        .tx        (uart_tx),
        .tx_busy   (uart_tx_busy)
    );


    // ---------------------------------------------------------
    // SPI Master
    // ---------------------------------------------------------

    logic [7:0] spi_tx_data;
    logic [7:0] spi_rx_data;
    logic       spi_start;
    logic       spi_done;
    logic       spi_busy;

    spi_master #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .SPI_FREQ_HZ(SPI_FREQ_HZ)
    ) u_spi_master (
        .clk       (clk),
        .rst_n     (rst_n),

        .spi_start (spi_start),
        .tx_data   (spi_tx_data),
        .rx_data   (spi_rx_data),
        .spi_done  (spi_done),

        .spi_mosi  (spi_mosi),
        .spi_miso  (spi_miso),
        .spi_sclk  (spi_sclk),
        .spi_cs_n  (spi_cs_n),
        .spi_busy  (spi_busy)
    );


    // ---------------------------------------------------------
    // UART-SPI Controller
    // ---------------------------------------------------------

    uart_spi_controller u_controller (
        .clk           (clk),
        .rst_n         (rst_n),

        // UART RX
        .uart_rx_data  (uart_rx_data),
        .uart_rx_valid (uart_rx_valid),

        // UART TX
        .uart_tx_data  (uart_tx_data),
        .uart_tx_start (uart_tx_start),
        .uart_tx_busy  (uart_tx_busy),

        // SPI
        .spi_tx_data   (spi_tx_data),
        .spi_start     (spi_start),
        .spi_rx_data   (spi_rx_data),
        .spi_done      (spi_done)
    );

endmodule