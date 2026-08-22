import riscv_pkg::*;
module stage_if (
input logic clk,
input logic rst_n,

input logic stall,
input logic ex_redirect,
input logic [31:0] ex_redirect_pc,

output if_id_t if_id_d,
output logic [31:0] if_inst
);

    assign if_id_d.valid  = 1'b1;

pc pc (
    .clk(clk),
    .rst_n(rst_n),

    .stall(stall),
    .ex_redirect(ex_redirect),
    .ex_redirect_pc(ex_redirect_pc),

    .pc_out(if_id_d.pc)
);

instruction_cache instruction_cache(
    .clk(clk),
    .stall(stall),
    .pc(if_id_d.pc),

    .inst(if_inst)
);

endmodule