module uart_tx (
    input  logic       clk,
    input  logic       rst_n,

    input  logic [7:0] data_in,
    input  logic       tx_start,

    input  logic       baud_tick,

    output logic       tx,
    output logic       tx_busy
);

    typedef enum logic [1:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    } state_t;

    state_t state;

    logic [7:0] tx_data;
    logic [2:0] bit_count;

    always_ff @(posedge clk) begin

        if (!rst_n) begin
            state    <= IDLE;
            tx       <= 1'b1;
            tx_busy  <= 1'b0;
            tx_data  <= 8'b0;
            bit_count <= 3'b0;
        end

        else begin

            case (state)

                IDLE: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;

                    if (tx_start) begin
                        tx_data  <= data_in;
                        bit_count <= 3'b0;
                        tx_busy  <= 1'b1;
                        state    <= START_BIT;
                    end
                end

                START_BIT: begin
                    if (baud_tick) begin
                        tx    <= 1'b0;
                        state <= DATA_BITS;
                    end
                end

                DATA_BITS: begin
                    if (baud_tick) begin
                        tx <= tx_data[bit_count];

                        if (bit_count == 3'd7) begin
                            bit_count <= 3'b0;
                            state <= STOP_BIT;
                        end
                        else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end

                STOP_BIT: begin
                    if (baud_tick) begin
                        tx    <= 1'b1;
                        state <= IDLE;
                    end
                end

                default: begin
                    state   <= IDLE;
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;
                end

            endcase
        end
    end

endmodule