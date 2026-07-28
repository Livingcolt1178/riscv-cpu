import riscv_pkg::*;
module build_imm (
    input logic [31:0] inst,
    input format_t [2:0] format,

    output logic [31:0] imm
);

always_comb begin
    case(format)
        I: imm = {{20{inst[31]}}, inst[31:20]};
        S: imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
        B: imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        U: imm = {inst[31:12], {12'b0}};
        J: imm = {{12{inst[31]}},inst[19:12],inst[20], inst[30:21],1'b0};
        default: imm = 32'b0;
    endcase
end

endmodule