`timescale 1ns/1ps
module top_lvl
import riscv_pkg::*;
(
    input logic clk_i,
    input logic rst_ni,

    output logic led_green_o
);

if_id_t if_id_d;
if_id_t if_id_q;

id_ex_t id_ex_d;
id_ex_t id_ex_q;

ex_mem_t ex_mem_d;
ex_mem_t ex_mem_q;

mem_wb_t mem_wb_d;
mem_wb_t mem_wb_q;

logic stall_if;
logic stall_id;
logic stall_ex;
logic stall_mem;
logic stall_wb;

logic flush_id;
logic flush_ex;
logic flush_mem;
logic flush_wb;

logic ex_redirect;
logic [31:0] ex_redirect_pc;
logic [31:0] id_rs1_data;
logic [31:0] id_rs2_data;

fwd_sel_t fwd_a;
fwd_sel_t fwd_b;

logic load_use_hazard;
logic [31:0] wb_dmem_out;
logic mem_we_dmem;
logic mem_we_periph;

logic [31:0] if_inst;
logic [31:0] id_inst;
logic [31:0] wb_data;

(* ASYNC_REG = "TRUE" *) logic rst_q, rst_q2;
logic rst_n;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if(!rst_ni) begin
        rst_q <= 1'b0;
        rst_q2 <= 1'b0;
    end else begin
        rst_q <= rst_ni;
        rst_q2 <= rst_q;
    end
end
assign rst_n = rst_q2;

assign load_use_hazard = id_ex_q.valid && (id_ex_q.op_class == Load && id_ex_q.wb.rd != 0 &&
                         ((id_ex_q.wb.rd == id_inst[19:15]) || (id_ex_q.wb.rd == id_inst[24:20])));
assign stall_if = load_use_hazard;

stage_if u_stage_if(
    .clk_i(clk_i),
    .rst_ni(rst_n),

    .stall_i(stall_if),
    .ex_redirect_i(ex_redirect),
    .ex_redirect_pc_i(ex_redirect_pc),

    .if_id_o(if_id_d),
    .if_inst_o(if_inst)
);

assign flush_id = ex_redirect;
assign stall_id = load_use_hazard;

always_ff @(posedge clk_i) begin
    if (!rst_n)          if_id_q.valid <= 0;
    else if (flush_id)   if_id_q.valid <= 0;
    else if (!stall_id)  if_id_q <= if_id_d;
end

assign id_inst = flush_id ? '0 : if_inst;


reg_file u_reg_file(
    .clk_i(clk_i),

    .valid_i(mem_wb_q.valid),
    .we_i(mem_wb_q.wb.we_reg),    //comes back in from wb stage
    .rs1_addr_i(id_inst[19:15]),
    .rs2_addr_i(id_inst[24:20]),
    .wb_data_i(wb_data),          //comes back in from wb stage
    .wb_addr_i(mem_wb_q.wb.rd),    //comes back in from wb stage

    .rs1_data_o(id_rs1_data), //fed back into stage_id so that the total output comes from stage_id
    .rs2_data_o(id_rs2_data)  //fed back into stage_id so that the total output comes from stage_id
);

stage_id u_stage_id(
    .if_id_i(if_id_q),
    .id_inst_i(id_inst),
    .rs1_data_i(id_rs1_data),
    .rs2_data_i(id_rs2_data),

    .id_ex_o(id_ex_d)
);

assign flush_ex = ex_redirect || load_use_hazard;
assign stall_ex = 1'b0; //waiting on M extenstion


always_ff @(posedge clk_i) begin
    if (!rst_n)          id_ex_q.valid <= 0;
    else if (flush_ex)   id_ex_q.valid <= 0;
    else if (!stall_ex)  id_ex_q <= id_ex_d;
end

forwarding_unit u_forwarding_unit(
    .id_rs1_addr_i(id_ex_q.rs1_addr),
    .id_rs2_addr_i(id_ex_q.rs2_addr),

    .ex_valid_i(ex_mem_q.valid),
    .ex_wb_addr_i(ex_mem_q.wb.rd),
    .ex_we_i(ex_mem_q.wb.we_reg),

    .mem_valid_i(mem_wb_q.valid),
    .mem_wb_addr_i(mem_wb_q.wb.rd),
    .mem_we_i(mem_wb_q.wb.we_reg),

    .fwd_a_o(fwd_a),
    .fwd_b_o(fwd_b)
);

stage_ex u_stage_ex(
    .id_ex_i(id_ex_q),
    .fwd_ex_val_i(ex_mem_q.temp_wb_data),
    .fwd_mem_val_i(wb_data),
    .fwd_a_i(fwd_a),
    .fwd_b_i(fwd_b),

    .ex_mem_o(ex_mem_d),
    .ex_redirect_o(ex_redirect),//not pipelined
    .ex_redirect_pc_o(ex_redirect_pc) //not pipelined
);

assign flush_mem = 1'b0; //implemented at L5
assign stall_mem = 1'b0; //implemented at L4

always_ff @(posedge clk_i) begin
    if (!rst_n)           ex_mem_q.valid <= 0;
    else if (flush_mem)   ex_mem_q.valid <= 0;
    else if (!stall_mem)  ex_mem_q <= ex_mem_d;
end

mmio_unit u_mmio_unit(
    .valid_i(ex_mem_q.valid),
    .mem_addr_i(ex_mem_q.alu_result),
    .we_i(ex_mem_q.mem.we_mem),

    .we_dmem_o(mem_we_dmem),
    .we_periph_o(mem_we_periph)
);

data_mem u_data_mem(
    .clk_i(clk_i),

    .valid_i(ex_mem_q.valid),
    .addr_i(ex_mem_q.alu_result),
    .mem_i(ex_mem_q.rs2_data),
    .fct3_i(ex_mem_q.mem.fct3),
    .we_i(mem_we_dmem),

    .dmem_o(wb_dmem_out)
);

stage_mem u_stage_mem(
    .ex_mem_i(ex_mem_q),

    .mem_wb_o(mem_wb_d)
);

assign flush_wb = 1'b0; //implemented at L4
assign stall_wb = 1'b0; // WB never stalls: nothing downstream can block it

always_ff @(posedge clk_i) begin
    if (!rst_n)          mem_wb_q.valid <= 0;
    else if (flush_wb)   mem_wb_q.valid <= 0;
    else if (!stall_wb)  mem_wb_q <= mem_wb_d;
end

stage_wb u_stage_wb(
    .mem_wb_i(mem_wb_q),
    .dmem_i(wb_dmem_out),

    .wb_data_o(wb_data)
);

//IO's
led_io u_led_io(
    .clk_i(clk_i),
    .rst_ni(rst_n),
    .we_periph_i(mem_we_periph),
    .mem_i(ex_mem_q.rs2_data),

    .led_green_o(led_green_o)
);
endmodule
