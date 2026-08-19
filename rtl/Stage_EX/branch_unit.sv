module branch_unit(
input logic [31:0] alu_out,
input logic [2:0] fct3,

output logic br
);
    always_comb begin
        case(fct3)
            3'b000: br = (alu_out == 0);    //BEQ
            3'b001: br = (alu_out != 0);    //BNE
            3'b100: br = (alu_out == 1);    //BLT
            3'b101: br = (alu_out == 0);    //BGE
            3'b110: br = (alu_out == 1);    //BLTU
            3'b111: br = (alu_out == 0);    //BGEU
            default : br = 0;
        endcase
    end

endmodule