`timescale 1ns/1ps
module FPGA_top(
    input logic clk_100_i,
    input logic rst_button_ni,

    output logic led_green_o
);
// the reason for this wrapper is due implemenation with different clk speeds, in the future, the clk wizard or mmcm would be instantiated here.




logic clk_in;
logic clk_div_q = 1'b0;
always_ff @(posedge clk_100_i) begin
  clk_div_q <= ~clk_div_q;
end

BUFG bufg_core (.I(clk_div_q), .O(clk_in));

top_lvl top_lvl (
    .clk_i(clk_in),
    .rst_ni(rst_button_ni),

    .led_green_o(led_green_o)
);
endmodule
