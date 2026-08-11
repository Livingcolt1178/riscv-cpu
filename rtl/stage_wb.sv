import riscv_pkg::*;
module stage_wb (
    input mem_wb_t mem_wb_q,

    output logic [31:0] WBval
);

WB_sel_mux WB_sel_mux(
    .alu(mem_wb_q.alu_out),
    .mem(mem_wb_q.mem_out),
    .pc(mem_wb_q.pc),
    .op_class(mem_wb_q.op_class),  //cu
    .ta(mem_wb_q.ta),

    .WBval(WBval)
);
endmodule