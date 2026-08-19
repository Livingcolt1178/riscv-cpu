import riscv_pkg::*;
module WB_sel_mux(
    input logic [31:0] alu,
    input logic [31:0] pc,
    input logic [31:0] ta,
    input op_class_t op_class,

    output logic [31:0] WBval
);

logic [31:0] pc_plus4;

assign pc_plus4 = pc + 32'd4;

always_comb begin
    case(op_class)
        ALU :   WBval = alu;    //done in EX
        JUMP:   WBval = pc_plus4;   //done in IF even
        JUMPR:  WBval = pc_plus4;   //done in IF even
        LUI:    WBval = ta;         //done in EX
        AUIPC:  WBval = ta;     //done in EX
        default WBval = alu;
    endcase
end


endmodule