import riscv_pkg::*;
module control_unit(
    input logic [6:0] fct7,
    input logic [6:0] opcode,

    output op_class_t op_class,
    output logic alu_modifier,
    output logic we_mem, //not S and B
    output logic we_reg,
    output format_t  format,
    output logic alu_s2_ctrl
    );
/*  Thought Box
We need we for all opcodes except S and B
the purpose of op_class is to tell what is happening elsewhere, changed to be enum.
Format is important mainly for build_imm so it knows how to format the imm.


*/
always_comb begin
    op_class     = NOP;
    format       = I;
    we_mem       = 1'b0;
    we_reg       = 1'b0;
    alu_modifier = 1'b0;
    alu_s2_ctrl  = 1'b0;
    case(opcode)

        //ALU R
        7'b0110011: begin
            op_class = ALU;
            format = R;
            alu_modifier = fct7[5];
            we_reg = 1;
            alu_s2_ctrl = 1;
        end

        //ALU I
        7'b0010011: begin
            op_class = ALU;
            format = I;
            alu_modifier = fct7[5];
            we_reg = 1;
        end

        //L/S Load I
        7'b0000011:begin
            op_class = LOAD;
            format = I;
            we_reg = 1;
        end

        //L/S Store S
        7'b0100011: begin
            op_class = STORE;
            format = S;
            we_mem = 1;
        end

        //System I
        7'b1110011: begin
            format = I;
            op_class = NOP;
        end

        //Branch B
        7'b1100011: begin
            op_class = BRANCH;
            format = B;
            alu_s2_ctrl = 1;
        end

        //LUI U
        7'b0110111: begin
            op_class = LUI;
            format = U;
            we_reg = 1;
        end

        //AUIPC U
        7'b0010111:begin
            op_class = AUIPC;
            format = U;
            we_reg = 1;
        end

        //Jump JAL J
        7'b1101111: begin
            op_class = JUMP;
            format = J;
            we_reg = 1;
        end

        //Jump JALR I
        7'b1100111: begin
            op_class = JUMPR;
            format = I;
            we_reg = 1;
        end

        //Fence I
        7'b0001111: begin
            op_class = FENCE;
            format = I;
        end
        default: begin

        end
    endcase
end
endmodule