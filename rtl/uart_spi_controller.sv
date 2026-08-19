module uart_spi_controller (
    input  logic       clk,
    input  logic       rst_n,

    // UART RX interface
    input  logic [7:0] uart_rx_data,
    input  logic       uart_rx_valid,

    // UART TX interface
    output logic [7:0] uart_tx_data,
    output logic       uart_tx_start,
    input  logic       uart_tx_busy,

    // SPI interface
    output logic [7:0] spi_tx_data,
    output logic       spi_start,
    input  logic [7:0] spi_rx_data,
    input  logic       spi_done
);

    typedef enum logic [2:0] {
        IDLE,
        WAIT_DATA,
        START_SPI,
        WAIT_SPI,
        START_UART_TX,
        WAIT_UART_TX
    } state_t;

    state_t state;

    logic [7:0] command_reg;
    logic [7:0] data_reg;

    always_ff @(posedge clk) begin

        if (!rst_n) begin
            state          <= IDLE;

            command_reg    <= 8'h00;
            data_reg       <= 8'h00;

            uart_tx_data   <= 8'h00;
            uart_tx_start  <= 1'b0;

            spi_tx_data    <= 8'h00;
            spi_start      <= 1'b0;
        end
        else begin

            // Default: pulse signals are low
            uart_tx_start <= 1'b0;
            spi_start     <= 1'b0;

            case (state)

                // -------------------------------------------------
                // Wait for a UART command
                // -------------------------------------------------
                IDLE: begin

                    if (uart_rx_valid) begin

                        command_reg <= uart_rx_data;

                        if (uart_rx_data == 8'h01)
                            state <= WAIT_DATA;
                        else
                            state <= IDLE;

                    end
                end


                // -------------------------------------------------
                // Wait for SPI transmit data
                // -------------------------------------------------
                WAIT_DATA: begin

                    if (uart_rx_valid) begin
                        data_reg <= uart_rx_data;
                        state <= START_SPI;
                    end

                end


                // -------------------------------------------------
                // Start SPI transaction
                // -------------------------------------------------
                START_SPI: begin

                    spi_tx_data <= data_reg;
                    spi_start   <= 1'b1;

                    state <= WAIT_SPI;

                end


                // -------------------------------------------------
                // Wait for SPI completion
                // -------------------------------------------------
                WAIT_SPI: begin

                    if (spi_done) begin
                        uart_tx_data <= spi_rx_data;
                        state <= START_UART_TX;
                    end

                end


                // -------------------------------------------------
                // Start UART transmission
                // -------------------------------------------------
                START_UART_TX: begin

                    if (!uart_tx_busy) begin
                        uart_tx_start <= 1'b1;
                        state <= WAIT_UART_TX;
                    end

                end


                // -------------------------------------------------
                // Wait until UART transmitter becomes free
                // -------------------------------------------------
                WAIT_UART_TX: begin

                    if (!uart_tx_busy) begin
                        state <= IDLE;
                    end

                end


                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule