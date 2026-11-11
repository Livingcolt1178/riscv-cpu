`timescale 1ns/1ps
module control_unit
import riscv_pkg::*;
(
    input logic [6:0] fct7_i,
    input logic [6:0] opcode_i,

    output op_class_t op_class_o,
    output logic alu_modifier_o,
    output logic we_mem_o, //not S and B
    output logic we_reg_o,
    output format_t  format_o,
    output logic alu_s2_ctrl_o
    );
/*  Thought Box
We need we for all opcodes except S and B
the purpose of op_class is to tell what is happening elsewhere, changed to be enum.
Format is important mainly for build_imm so it knows how to format the imm.


*/
always_comb begin
    op_class_o     = Nop;
    format_o       = I;
    we_mem_o       = 1'b0;
    we_reg_o       = 1'b0;
    alu_modifier_o = 1'b0;
    alu_s2_ctrl_o  = 1'b0;
    unique case(opcode_i)

        //ALU R
        7'b0110011: begin
            op_class_o = Alu;
            format_o = R;
            alu_modifier_o = fct7_i[5];
            we_reg_o = 1;
            alu_s2_ctrl_o = 1;
        end

        //ALU I
        7'b0010011: begin
            op_class_o = Alu;
            format_o = I;
            alu_modifier_o = fct7_i[5];
            we_reg_o = 1;
        end

        //L/S Load I
        7'b0000011:begin
            op_class_o = Load;
            format_o = I;
            we_reg_o = 1;
        end

        //L/S Store S
        7'b0100011: begin
            op_class_o = Store;
            format_o = S;
            we_mem_o = 1;
        end

        //System I
        7'b1110011: begin
            format_o = I;
            op_class_o = Nop;
        end

        //Branch B
        7'b1100011: begin
            op_class_o = Branch;
            format_o = B;
            alu_s2_ctrl_o = 1;
        end

        //LUI U
        7'b0110111: begin
            op_class_o = Lui;
            format_o = U;
            we_reg_o = 1;
        end

        //AUIPC U
        7'b0010111:begin
            op_class_o = Auipc;
            format_o = U;
            we_reg_o = 1;
        end

        //Jump JAL J
        7'b1101111: begin
            op_class_o = Jump;
            format_o = J;
            we_reg_o = 1;
        end

        //Jump JALR I
        7'b1100111: begin
            op_class_o = JumpR;
            format_o = I;
            we_reg_o = 1;
        end

        //Fence I
        7'b0001111: begin
            op_class_o = Fence;
            format_o = I;
        end
        default: begin

        end
    endcase
end
endmodule
