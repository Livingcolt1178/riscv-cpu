`timescale 1ns/1ps

module pc
import riscv_pkg::*;
(
    input logic clk_i,
    input logic rst_ni,

    input logic stall_i,
    input logic ex_redirect_i,
    input logic [31:0] ex_redirect_pc_i,

    output logic [31:0] pc_o
);

    logic [31:0] pc_next, pc_q;

    always_comb begin
        if(ex_redirect_i) begin
            pc_next = ex_redirect_pc_i;
        end else begin
            pc_next = pc_o + 32'd4;
        end
    end

    always_ff @( posedge clk_i) begin : blockName
        if (!rst_ni) begin
            pc_q <= 32'h8000_0000;
        end else if(stall_i) begin
            pc_q <= pc_q;
        end else begin
            pc_q <= pc_next;
        end
    end
    assign pc_o = pc_q;
endmodule
