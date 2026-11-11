`timescale 1ns/1ps
module stage_id
import riscv_pkg::*;
(
    input if_id_t if_id_i,
    input logic [31:0] id_inst_i,
    input logic [31:0] rs1_data_i,
    input logic [31:0] rs2_data_i,

    output id_ex_t id_ex_o
);

format_t format;
logic alu_modifier;

assign id_ex_o.valid        = if_id_i.valid;
assign id_ex_o.pc           = if_id_i.pc;
assign id_ex_o.ex.fct3      = id_inst_i[14:12];
assign id_ex_o.mem.fct3     = id_inst_i[14:12];
assign id_ex_o.wb.fct3      = id_inst_i[14:12];
assign id_ex_o.wb.rd        = id_inst_i[11:7];
assign id_ex_o.wb.lane      = '0;               // overwritten in stage_mem
assign id_ex_o.rs1_data     = rs1_data_i;
assign id_ex_o.rs2_data     = rs2_data_i;
assign id_ex_o.rs1_addr     = id_inst_i[19:15];  //used in forwarding
assign id_ex_o.rs2_addr     = id_inst_i[24:20];  //used in forwarding

//trace signals
assign id_ex_o.inst         = id_inst_i;


build_imm u_build_imm(
    .inst_i(id_inst_i),
    .format_i(format),        //internal

    .imm_o(id_ex_o.imm)
);

alu_control_unit u_alu_control_unit (
    .fct3_i(id_inst_i[14:12]),
    .alu_modifier_i(alu_modifier), //cu
    .op_class_i(id_ex_o.op_class),
    .format_i(format),

    .alu_fct3_o(id_ex_o.ex.alu_fct3)
);

control_unit u_control_unit(
    .fct7_i(id_inst_i[31:25]),
    .opcode_i(id_inst_i[6:0]),

    .op_class_o(id_ex_o.op_class),
    .alu_modifier_o(alu_modifier),//internal
    .we_mem_o(id_ex_o.mem.we_mem),
    .we_reg_o(id_ex_o.wb.we_reg),
    .format_o(format),//internal
    .alu_s2_ctrl_o(id_ex_o.ex.alu_s2_ctrl)
);
endmodule
