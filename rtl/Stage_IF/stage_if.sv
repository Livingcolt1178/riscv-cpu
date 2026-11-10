`timescale 1ns/1ps
module stage_if
import riscv_pkg::*;
(
input logic clk_i,
input logic rst_ni,

input logic stall_i,
input logic ex_redirect_i,
input logic [31:0] ex_redirect_pc_i,

output if_id_t if_id_o,
output logic [31:0] if_inst_o
);

assign if_id_o.valid  = 1'b1;

pc u_pc (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .stall_i(stall_i),
    .ex_redirect_i(ex_redirect_i),
    .ex_redirect_pc_i(ex_redirect_pc_i),

    .pc_o(if_id_o.pc)
);

instruction_mem u_instruction_mem(
    .clk_i(clk_i),
    .stall_i(stall_i),
    .pc_i(if_id_o.pc),

    .inst_o(if_inst_o)
);
endmodule
