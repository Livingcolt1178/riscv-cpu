import riscv_pkg::*;
module stage_mem (
    input logic clk,
    input ex_mem_t ex_mem_q,
    
    output mem_wb_t mem_wb_d
);

    logic [31:0] mem_out;

    assign mem_wb_d.valid       = ex_mem_q.valid;
    assign mem_wb_d.wb          = ex_mem_q.wb;

    //trace signals
    assign mem_wb_d.trace.op_class  = ex_mem_q.op_class;
    assign mem_wb_d.trace.pc        = ex_mem_q.pc;
    assign mem_wb_d.trace.alu_out   = ex_mem_q.alu_out; 
    assign mem_wb_d.trace.inst      = ex_mem_q.inst;
    assign mem_wb_d.trace.mem_wdata = ex_mem_q.S2val;
    assign mem_wb_d.trace.fct3      = ex_mem_q.mem.fct3;


data_cache data_cache(
    .clk(clk),

    .addr(ex_mem_q.alu_out),
    .mem_in(ex_mem_q.S2val),
    .fct3(ex_mem_q.mem.fct3),
    .we(ex_mem_q.mem.we_mem),

    .mem_out(mem_out)
);

    assign mem_wb_d.WBval = (ex_mem_q.op_class == LOAD) ? mem_out : ex_mem_q.WBval;

endmodule