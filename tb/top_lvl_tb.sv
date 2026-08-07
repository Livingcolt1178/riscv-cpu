`timescale 1ps/1ps
module top_lvl_tb;

    // Clock and reset signals
    logic clk;
    logic rst_n;

    // Instantiate the DUT (Device Under Test)
    top_lvl dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #20 rst_n = 1; // Release reset after 20 time units
    end
endmodule