`timescale 1ns/1ps

module baud_generator_tb;

    // Testbench signals
    logic clk;
    logic rst_n;
    logic baud_tick;

    // Instantiate DUT
    baud_generator #(
        .CLK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick)
    );

    // 100 MHz clock
    // Period = 10 ns
    always #5 clk = ~clk;

    // Test sequence
    initial begin

        clk = 1'b0;
        rst_n = 1'b0;

        // Hold reset
        #20;

        rst_n = 1'b1;

        // Run simulation
        #10000;

        $finish;
    end

endmodule