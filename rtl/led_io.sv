`timescale 1ns/1ps
module led_io(
    input logic clk_i,
    input logic rst_ni,
    input logic we_periph_i,
    input logic [31:0] mem_i,

    output logic led_green_o
);

logic led_green_q;

always_ff @(posedge clk_i) begin
    if(!rst_ni) begin
        led_green_q <= 0;
    end else begin
        if(we_periph_i && mem_i != 0) begin
            led_green_q <= 1;
        end else if (we_periph_i && mem_i == 0) begin
            led_green_q <= 0;
        end
    end
end

assign led_green_o = led_green_q;
endmodule
