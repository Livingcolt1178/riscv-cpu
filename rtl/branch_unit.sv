module branch_unit(
input logic [31:0] alu_out,
input logic [2:0] fct3,

output logic br
);
    always_comb begin
        case(fct3)
            3'b000: br = (alu_out == 0);
            3'b001: br = (alu_out != 0);
            3'b100: br = (alu_out == 1);
            
            3'b101: br = (alu_out == 0);
            3'b110: br = (alu_out == 1);
            3'b111: br = (alu_out == 0);
            default : br = 0;
        endcase
    end

endmodule