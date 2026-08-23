`timescale 1ns/1ps
module MMIO_unit(
    input logic valid,
    input logic [31:0] mem_addr,
    input logic we,
    //maybe periph_rdata?

    output logic we_dmem,
    output logic we_periph 
);
    logic is_mmio;
    assign is_mmio = (mem_addr < 32'h8000_0000 && mem_addr >= 32'h0000_1000);

    always_comb begin
        we_dmem = valid && we && ~is_mmio;
        we_periph = valid && we && is_mmio;
    end
endmodule