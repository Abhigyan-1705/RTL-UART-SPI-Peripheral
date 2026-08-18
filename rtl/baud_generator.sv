module baud_generator #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE   = 115200
)(
    input  logic clk,
    input  logic rst_n,

    output logic baud_tick
);

    // Number of clock cycles required for one baud period
    localparam integer BAUD_DIV = CLK_FREQ_HZ / BAUD_RATE;

    integer counter;

    always_ff @(posedge clk) begin

        if (!rst_n) begin
            counter   <= 0;
            baud_tick <= 1'b0;
        end
        else begin

            if (counter == BAUD_DIV - 1) begin
                counter   <= 0;
                baud_tick <= 1'b1;
            end
            else begin
                counter   <= counter + 1;
                baud_tick <= 1'b0;
            end

        end
    end

endmodule