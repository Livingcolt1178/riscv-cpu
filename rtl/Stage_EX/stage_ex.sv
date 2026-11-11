`timescale 1ns/1ps
module stage_ex
import riscv_pkg::*;
(
    input id_ex_t id_ex_i,
    input logic [31:0] fwd_ex_val_i,
    input logic [31:0] fwd_mem_val_i,
    input fwd_sel_t fwd_a_i,
    input fwd_sel_t fwd_b_i,

    output ex_mem_t ex_mem_o,
    output logic ex_redirect_o,
    output logic[31:0] ex_redirect_pc_o
);


logic br;
logic [31:0] rs1_fwd, rs2_fwd;
logic [31:0] ta;

//driven signals to future stages
assign ex_mem_o.valid       = id_ex_i.valid;
assign ex_mem_o.rs2_data    = rs2_fwd;
assign ex_mem_o.op_class    = id_ex_i.op_class;
assign ex_mem_o.mem         = id_ex_i.mem;
assign ex_mem_o.wb          = id_ex_i.wb;

//trace signals
assign ex_mem_o.pc          = id_ex_i.pc;
assign ex_mem_o.inst        = id_ex_i.inst;

assign ex_redirect_pc_o = ta;
assign ex_redirect_o = id_ex_i.valid &&
                        (((ex_mem_o.op_class == Branch) && br)
                        || (ex_mem_o.op_class == Jump)
                        || (ex_mem_o.op_class == JumpR));

always_comb begin
    unique case(fwd_a_i)
        FwdEx: rs1_fwd = fwd_ex_val_i;
        FwdMem: rs1_fwd = fwd_mem_val_i;
        default: rs1_fwd = id_ex_i.rs1_data;
    endcase
    unique case(fwd_b_i)
        FwdEx: rs2_fwd = fwd_ex_val_i;
        FwdMem: rs2_fwd = fwd_mem_val_i;
        default: rs2_fwd = id_ex_i.rs2_data;
    endcase
end

target_address_constructor u_target_address_constructor(
    .imm_i(id_ex_i.imm),
    .pc_i(id_ex_i.pc),
    .rs1_data_i(rs1_fwd),
    .op_class_i(id_ex_i.op_class),

    .ta_o(ta)
);

alu u_alu(
    .val1_i(rs1_fwd),
    .val2_i(id_ex_i.ex.alu_s2_ctrl ? rs2_fwd : id_ex_i.imm),
    .alu_fct3_i(id_ex_i.ex.alu_fct3),

    .alu_result_o(ex_mem_o.alu_result)
);

branch_unit u_branch_unit(
    .alu_result_i(ex_mem_o.alu_result),
    .fct3_i(id_ex_i.ex.fct3),

    .br_o(br)
);

wb_sel_mux u_wb_sel_mux(
    .alu_i(ex_mem_o.alu_result),
    .pc_i(ex_mem_o.pc),
    .op_class_i(ex_mem_o.op_class),  //cu
    .ta_i(ta),

    .wb_val_o(ex_mem_o.temp_wb_data)
);
endmodule
