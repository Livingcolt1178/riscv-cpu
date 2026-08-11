import riscv_pkg::*;
module stage_mem (
    input logic clk,
    input ex_mem_t ex_mem_q,
    
    output mem_wb_t mem_wb_d
);

    assign mem_wb_d.valid   = ex_mem_q.valid;
    assign mem_wb_d.pc      = ex_mem_q.pc;
    assign mem_wb_d.inst    = ex_mem_q.inst;
    assign mem_wb_d.ta      = ex_mem_q.ta;
    assign mem_wb_d.alu_out = ex_mem_q.alu_out;
    assign mem_wb_d.op_class= ex_mem_q.op_class;
    assign mem_wb_d.wb      = ex_mem_q.wb;

data_cache data_cache(
    .clk(clk),

    .addr(ex_mem_q.alu_out),
    .mem_in(ex_mem_q.S2val),
    .fct3(ex_mem_q.mem.fct3),
    .we(ex_mem_q.mem.we_mem),

    .mem_out(mem_wb_d.mem_out)
);
endmodule