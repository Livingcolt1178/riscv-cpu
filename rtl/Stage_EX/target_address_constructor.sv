`timescale 1ns/1ps
module target_address_constructor
import riscv_pkg::*;
(
input logic [31:0] imm_i,
input logic [31:0] pc_i,
input logic [31:0] rs1_data_i,
input op_class_t op_class_i,

output logic [31:0] ta_o
);

logic [31:0] base;

always_comb begin
    unique case(op_class_i)
        Branch:  base = pc_i;
        Jump:    base = pc_i;
        JumpR:   base = rs1_data_i;
        Lui:     base = 0;
        Auipc:   base = pc_i;
        default: base = pc_i;
    endcase

    if(op_class_i == JumpR) begin
        ta_o = {(base + imm_i) & ~32'd1};
    end else begin
        ta_o = base + imm_i;
    end
end
endmodule
