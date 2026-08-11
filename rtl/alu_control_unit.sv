import riscv_pkg::*;
module alu_control_unit (
    input logic [2:0] fct3,
    input logic alu_modifier,
    input op_class_t op_class, //this will be what tells the ALU what type of op_class we are doing, whether it be a simple ALU, branch, or Jump. op_class 2 is reserved for memory for WB_sel_mux
    input format_t format,

    output alu_fct3_t alu_fct3
);

    always_comb begin 
        case(op_class)
            ALU: begin
                case(fct3)
                    3'b000: if(alu_modifier == 1 && format != I) begin
                        alu_fct3 = ALU_SUB;
                    end else begin
                        alu_fct3 = ALU_ADD;
                    end
                    3'b001: alu_fct3 = ALU_SLL;
                    3'b010: alu_fct3 = ALU_SLT;
                    3'b011: alu_fct3 = ALU_SLTU;
                    3'b100: alu_fct3 = ALU_XOR;
                    3'b101: if( alu_modifier == 0) begin
                        alu_fct3 = ALU_SRL;
                    end else begin
                        alu_fct3 = ALU_SRA;
                    end
                    3'b110: alu_fct3 = ALU_OR;
                    3'b111: alu_fct3 = ALU_AND;
                endcase
            end
            LOAD: begin
                alu_fct3 = ALU_ADD;
            end
            STORE: begin
                alu_fct3 = ALU_ADD;
            end
            BRANCH: begin
                case(fct3)
                    3'b000: alu_fct3 = ALU_SUB;
                    3'b001: alu_fct3 = ALU_SUB;
                    3'b100: alu_fct3 = ALU_SLT;
                    3'b101: alu_fct3 = ALU_SLT;
                    3'b110: alu_fct3 = ALU_SLTU;
                    3'b111: alu_fct3 = ALU_SLTU;
                    default : alu_fct3 = ALU_ADD;
                endcase
            end
            
            default: alu_fct3 = ALU_ADD;
        endcase
    end
endmodule