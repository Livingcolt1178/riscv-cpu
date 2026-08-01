import riscv_pkg::*;
module target_address_constructor(
input logic [31:0] imm,
input logic [31:0] pc,
input logic [31:0] rs1, 
input op_class_t op_class,

output logic [31:0] ta
);

logic [31:0] base;

always_comb begin
    case(op_class) 
        BRANCH: base = pc;
        JUMP:   base = pc;
        JUMPR:  base = rs1;
        LUI:    base = 0;
        AUIPC:  base = pc;
        default: base = pc;
    endcase
end 
assign ta = base + imm;

endmodule