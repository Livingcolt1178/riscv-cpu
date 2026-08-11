import riscv_pkg::*;
module stage_ex (
    input id_ex_t id_ex_q,

    output ex_mem_t ex_mem_d,
    output logic ex_redirect,
    output logic[31:0] ex_redirect_pc
);

//so ex needs, imm, pc, s1val, op_class, alu_fct3, s2val, fct3

//ex_mem_d needs, ta, alu_out, br
logic br;

//what is driven from outputs: ta, alu_out, br
//what is needed to be driving:pc, inst, s2val, opclass,mem,wb
assign ex_mem_d.valid       = id_ex_q.valid;
assign ex_mem_d.pc          = id_ex_q.pc;
assign ex_mem_d.inst        = id_ex_q.inst;
assign ex_mem_d.S2val       = id_ex_q.S2val;
assign ex_mem_d.op_class    = id_ex_q.op_class;
assign ex_mem_d.mem         = id_ex_q.mem;
assign ex_mem_d.wb          = id_ex_q.wb;

assign ex_redirect_pc = ex_mem_d.ta;
always_comb begin
    if((ex_mem_d.op_class == BRANCH && br == 1) || ex_mem_d.op_class == JUMP || ex_mem_d.op_class == JUMPR) begin
        ex_redirect = 1;
    end else begin
        ex_redirect = 0;
    end
end

target_address_constructor target_address_constructor(
    .imm(id_ex_q.imm),
    .pc(id_ex_q.pc),
    .S1val(id_ex_q.S1val),
    .op_class(id_ex_q.op_class),
        
    .ta(ex_mem_d.ta)
);

alu alu(
    .val1(id_ex_q.S1val),
    .val2(id_ex_q.ex.alu_s2_ctrl ? id_ex_q.S2val : id_ex_q.imm),
    .alu_fct3(id_ex_q.ex.alu_fct3),

    .alu_out(ex_mem_d.alu_out)
);

branch_unit branch_unit(
    .alu_out(ex_mem_d.alu_out),
    .fct3(id_ex_q.ex.fct3),

    .br(br)
);

endmodule