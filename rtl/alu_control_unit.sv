import riscv_pkg::*;
module alu_control_unit (
input logic [2:0] fct3,
input logic alu_modifier,
input op_class_t op_class, //this will be what tells the ALU what type of op_class we are doing, whether it be a simple ALU, branch, or Jump. op_class 2 is reserved for memory for WB_sel_mux
input format_t format,

output ALU_fct3_t ALU_fct3
);

    always_comb begin 
        case(op_class)
            ALU: begin
                case(fct3)
                    3'b000: if(alu_modifier == 1 && format != I) begin
                        ALU_fct3 = ALU_SUB;
                    end else begin
                        ALU_fct3 = ALU_ADD;
                    end
                    3'b001: ALU_fct3 = ALU_SLL;
                    3'b010: ALU_fct3 = ALU_SLT;
                    3'b011: ALU_fct3 = ALU_SLTU;
                    3'b100: ALU_fct3 = ALU_XOR;
                    3'b101: if( alu_modifier == 0) begin
                        ALU_fct3 = ALU_SRL;
                    end else begin
                        ALU_fct3 = ALU_SRA;
                    end
                    3'b110: ALU_fct3 = ALU_OR;
                    3'b111: ALU_fct3 = ALU_AND;
                    default : ALU_fct3 = ALU_ADD;
                endcase
            end
            LOAD: begin
                ALU_fct3 = ALU_ADD;
            end
            STORE: begin
                ALU_fct3 = ALU_ADD;
            end
            BRANCH: begin
                case(fct3)
                    3'b000: ALU_fct3 = ALU_SUB;
                    3'b001: ALU_fct3 = ALU_SUB;
                    3'b100: ALU_fct3 = ALU_SLT;
                    3'b101: ALU_fct3 = ALU_SLT;
                    3'b110: ALU_fct3 = ALU_SLTU;
                    3'b111: ALU_fct3 = ALU_SLTU;
                    default : ALU_fct3 = ALU_ADD;
                endcase
            end
            
            default: ALU_fct3 = ALU_ADD;
        endcase
    end
endmodule