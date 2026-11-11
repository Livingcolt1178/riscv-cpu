`timescale 1ns/1ps
module branch_unit
import riscv_pkg::*;
(
input logic [31:0] alu_result_i,
input logic [2:0] fct3_i,

output logic br_o
);
    always_comb begin
        unique case(fct3_i)
            3'b000: br_o = (alu_result_i == 0);    //BEQ
            3'b001: br_o = (alu_result_i != 0);    //BNE
            3'b100: br_o = (alu_result_i == 1);    //BLT
            3'b101: br_o = (alu_result_i == 0);    //BGE
            3'b110: br_o = (alu_result_i == 1);    //BLTU
            3'b111: br_o = (alu_result_i == 0);    //BGEU
            default : br_o = 0;
        endcase
    end
endmodule
