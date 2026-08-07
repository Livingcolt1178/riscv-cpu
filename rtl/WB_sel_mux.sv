import riscv_pkg::*;
module WB_sel_mux(
    input logic [31:0] alu,
    input logic [31:0] mem,
    input logic [31:0] pc_plus4,
    input logic [31:0] ta,
    input op_class_t op_class,

    output logic [31:0] WBval
);

always_comb begin
    case(op_class)
        ALU :   WBval = alu;
        LOAD :  WBval = mem; 
        JUMP:   WBval = pc_plus4;
        JUMPR:  WBval = pc_plus4;
        LUI:    WBval = ta;
        AUIPC:  WBval = ta;
        default WBval = alu;
    endcase
end


endmodule