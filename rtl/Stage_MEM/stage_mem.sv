`timescale 1ns/1ps
module stage_mem
import riscv_pkg::*;
(
    input ex_mem_t ex_mem_i,

    output mem_wb_t mem_wb_o
);
    assign mem_wb_o.valid           = ex_mem_i.valid;
    assign mem_wb_o.temp_wb_data    = ex_mem_i.temp_wb_data;
    assign mem_wb_o.op_class        = ex_mem_i.op_class;
    assign mem_wb_o.wb.we_reg       = ex_mem_i.wb.we_reg;
    assign mem_wb_o.wb.rd           = ex_mem_i.wb.rd;
    assign mem_wb_o.wb.fct3         = ex_mem_i.wb.fct3;
    assign mem_wb_o.wb.lane         = ex_mem_i.alu_result[1:0];

    //trace signals
    assign mem_wb_o.trace.pc            = ex_mem_i.pc;
    assign mem_wb_o.trace.alu_result    = ex_mem_i.alu_result;
    assign mem_wb_o.trace.inst          = ex_mem_i.inst;
    assign mem_wb_o.trace.mem_wdata     = ex_mem_i.rs2_data;
    assign mem_wb_o.trace.fct3          = ex_mem_i.mem.fct3;
endmodule
