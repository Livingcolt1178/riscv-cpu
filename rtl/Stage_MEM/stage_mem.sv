import riscv_pkg::*;
module stage_mem (
    input ex_mem_t ex_mem_q,
    
    output mem_wb_t mem_wb_d
);
    assign mem_wb_d.valid       = ex_mem_q.valid;
    assign mem_wb_d.temp_WBval  = ex_mem_q.temp_WBval;
    assign mem_wb_d.op_class    = ex_mem_q.op_class;
    assign mem_wb_d.wb.we_reg   = ex_mem_q.wb.we_reg;
    assign mem_wb_d.wb.rd       = ex_mem_q.wb.rd;
    assign mem_wb_d.wb.fct3     = ex_mem_q.wb.fct3;
    assign mem_wb_d.wb.lane     = ex_mem_q.alu_out[1:0];

    //trace signals
    assign mem_wb_d.trace.pc        = ex_mem_q.pc;
    assign mem_wb_d.trace.alu_out   = ex_mem_q.alu_out; 
    assign mem_wb_d.trace.inst      = ex_mem_q.inst;
    assign mem_wb_d.trace.mem_wdata = ex_mem_q.S2val;
    assign mem_wb_d.trace.fct3      = ex_mem_q.mem.fct3;

endmodule