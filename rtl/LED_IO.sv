module LED_IO(
    input logic clk,
    input logic rst_n,
    input logic we_periph,
    input logic [31:0] mem_in,

    output logic led_green
);

always_ff @(posedge clk) begin
    if(!rst_n) begin
        led_green <= 0;
    end else begin
        if(we_periph && mem_in != 0) begin
            led_green <= 1;
        end
    end

end
endmodule