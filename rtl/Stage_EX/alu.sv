`timescale 1ns/1ps
module alu
import riscv_pkg::*;
(
    input logic [31:0] val1_i,
    input logic [31:0] val2_i,
    input alu_fct3_t alu_fct3_i,

    output logic [31:0] alu_result_o
);
    logic [4:0] shamt;
    assign shamt = val2_i [4:0];

    // Function of ALU
    always_comb begin
        unique case(alu_fct3_i)
            AluAdd     : alu_result_o = val1_i + val2_i;
            AluSub     : alu_result_o = val1_i - val2_i;
            AluSll     : alu_result_o = val1_i << shamt;
            //this checks iif val1 is less than val 2 if true it sets output to 1.
            AluSlt     : alu_result_o = ($signed(val1_i) < $signed(val2_i)) ? 32'd1 : 32'd0;
            AluSltu    : alu_result_o = (val1_i < val2_i) ? 32'd1 : 32'd0;
            AluXor     : alu_result_o = val1_i ^ val2_i;
            AluSrl     : alu_result_o = val1_i >> shamt;
            //this preserves the sign, logical merely fills it with zeros.
            AluSra     : alu_result_o = $signed(val1_i) >>> shamt;
            AluOr      : alu_result_o = val1_i | val2_i;
            AluAnd     : alu_result_o = val1_i & val2_i;
            default: alu_result_o = '0;
        endcase
    end
endmodule
