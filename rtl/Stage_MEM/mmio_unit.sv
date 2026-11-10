`timescale 1ns/1ps
module mmio_unit(
    input logic valid_i,
    input logic [31:0] mem_addr_i,
    input logic we_i,
    //maybe periph_rdata?

    output logic we_dmem_o,
    output logic we_periph_o
);
    logic is_mmio;
    assign is_mmio = (mem_addr_i < 32'h8000_0000 && mem_addr_i >= 32'h0000_1000);

    always_comb begin
        we_dmem_o = valid_i && we_i && ~is_mmio;
        we_periph_o = valid_i && we_i && is_mmio;
    end
endmodule
