import riscv_pkg::*;
module control_unit(
    input logic [31:0] inst,
    input logic [6:0] opcode,

    output logic [2:0] action,
    output logic alu_modifier,
    output logic we, //not S and B
    output format_t  format
);

always_comb begin

case(opcode)

    //ALU R
    0110011: begin
        action = 1;
        alu_modifier = inst[30];
        format = R;
        we = 1;
    end

    //ALU I
    0010011: begin
        format = I;
        we = 1;
    end

    //L/S I
    0000011:begin
        format = I;
        we = 1;
        action = 2;
    end

    //L/S S
    0100011: begin
        format = S;
        action = 2;
    end

    //System I
    1110011: begin
        format = I;
        we = 1;
    end

    //Branch B
    1100011: begin
        format = B;

    end

    //LUI U
    0110111: begin
        format = U;
        we = 1;
    end

    //AUIPC U
    0010111:begin
        format = U;
        we = 1;
    end

    //Jump JAL J
    110111: begin
        format = J;
        we = 1;
        action = 3;
    end

    //Jump JALR I
    110011: begin
        format = I;
        we = 1;
        action = 3;
    end

    //Fence I
    0001111: begin
        format = I;
        we = 1;
    end

endcase

end



endmodule