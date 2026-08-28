`timescale 1ns/1ps
module FPGA_top(
    input wire clk_100,
    input wire rst_n_button,

    output wire led_green
);
// the reason for this wrapper is due implemenation with different clk speeds, in the future, the clk wizard or mmcm would be instantiated here.

logic clk_in;
logic clk_div = 1'b0;
always_ff @(posedge clk_100) clk_div <= ~clk_div;
BUFG bufg_core (.I(clk_div), .O(clk_in));

top_lvl top_lvl (
    .clk(clk_in),
    .rst_n_in(rst_n_button),
    .led_green(led_green)
);

endmodule