`timescale 1ns/1ps
module alu_control_unit
import riscv_pkg::*;
(
    input logic [2:0] fct3_i,
    input logic alu_modifier_i,
    //this will be what tells the ALU what type of op_class we are doing,
    //whether it be a simple ALU, branch, or Jump. op_class 2 is reserved for memory for WB_sel_mux
    input op_class_t op_class_i,
    input format_t format_i,

    output alu_fct3_t alu_fct3_o
);

    always_comb begin
        unique case(op_class_i)
            Alu: begin
                unique case(fct3_i)
                    3'b000: if(alu_modifier_i == 1 && format_i != I) begin
                        alu_fct3_o = AluSub;
                    end else begin
                        alu_fct3_o = AluAdd;
                    end
                    3'b001: alu_fct3_o = AluSll;
                    3'b010: alu_fct3_o = AluSlt;
                    3'b011: alu_fct3_o = AluSltu;
                    3'b100: alu_fct3_o = AluXor;
                    3'b101: if( alu_modifier_i == 0) begin
                        alu_fct3_o = AluSrl;
                    end else begin
                        alu_fct3_o = AluSra;
                    end
                    3'b110: alu_fct3_o = AluOr;
                    3'b111: alu_fct3_o = AluAnd;
                endcase
            end
            Load: begin
                alu_fct3_o = AluAdd;
            end
            Store: begin
                alu_fct3_o = AluAdd;
            end
            Branch: begin
                unique case(fct3_i)
                    3'b000: alu_fct3_o = AluSub;
                    3'b001: alu_fct3_o = AluSub;
                    3'b100: alu_fct3_o = AluSlt;
                    3'b101: alu_fct3_o = AluSlt;
                    3'b110: alu_fct3_o = AluSltu;
                    3'b111: alu_fct3_o = AluSltu;
                    default : alu_fct3_o = AluAdd;
                endcase
            end
            default: alu_fct3_o = AluAdd;
        endcase
    end
endmodule
