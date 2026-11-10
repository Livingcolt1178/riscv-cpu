`timescale 1ns/1ps
module wb_sel_mux
import riscv_pkg::*;
(
    input logic [31:0] alu_i,
    input logic [31:0] pc_i,
    input logic [31:0] ta_i,
    input op_class_t op_class_i,

    output logic [31:0] wb_val_o
);

logic [31:0] pc_plus4;

assign pc_plus4 = pc_i + 32'd4;

always_comb begin
    unique case(op_class_i)
        Alu:   wb_val_o = alu_i;    //done in EX
        Jump:   wb_val_o = pc_plus4;   //done in IF even
        JumpR:  wb_val_o = pc_plus4;   //done in IF even
        Lui:    wb_val_o = ta_i;         //done in EX
        Auipc:  wb_val_o = ta_i;     //done in EX
        default: wb_val_o = alu_i;
    endcase
end
endmodule
