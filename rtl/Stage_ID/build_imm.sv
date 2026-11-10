`timescale 1ns/1ps
module build_imm
import riscv_pkg::*;
(
    input logic [31:0] inst_i,
    input format_t format_i,

    output logic [31:0] imm_o
);

always_comb begin
    unique case(format_i)
        I: imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
        S: imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
        B: imm_o = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
        U: imm_o = {inst_i[31:12], {12'b0}};
        J: imm_o = {{12{inst_i[31]}},inst_i[19:12],inst_i[20], inst_i[30:21],1'b0};
        default: imm_o = 32'b0;
    endcase
end
endmodule
