import riscv_pkg::*;
module stage_ex (
    input id_ex_t id_ex_q,
    input logic [31:0] fwd_ex_val,
    input logic [31:0] fwd_mem_val,
    input fwd_sel_t fwd_a, 
    input fwd_sel_t fwd_b,

    output ex_mem_t ex_mem_d,
    output logic ex_redirect,
    output logic[31:0] ex_redirect_pc
);

//so ex needs, imm, pc, s1val, op_class, alu_fct3, s2val, fct3

//ex_mem_d needs, ta, alu_out, br
logic br;
logic [31:0] s1_fwd;
logic [31:0] s2_fwd;

//what is driven from outputs: ta, alu_out, br
//what is needed to be driving:pc, inst, s2val, opclass,mem,wb
assign ex_mem_d.valid       = id_ex_q.valid;
assign ex_mem_d.pc          = id_ex_q.pc;
assign ex_mem_d.inst        = id_ex_q.inst;
assign ex_mem_d.S2val       = s2_fwd;
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

always_comb begin
    case(fwd_a)
        FWD_EX: s1_fwd = fwd_ex_val;
        FWD_MEM: s1_fwd = fwd_mem_val;
        default: s1_fwd = id_ex_q.S1val;  
    endcase
    case(fwd_b)
        FWD_EX: s2_fwd = fwd_ex_val;
        FWD_MEM: s2_fwd = fwd_mem_val;
        default: s2_fwd = id_ex_q.S2val;  
    endcase
end

target_address_constructor target_address_constructor(
    .imm(id_ex_q.imm),
    .pc(id_ex_q.pc),
    .S1val(s1_fwd),
    .op_class(id_ex_q.op_class),
        
    .ta(ex_mem_d.ta)
);

alu alu(
    .val1(s1_fwd),
    .val2(id_ex_q.ex.alu_s2_ctrl ? s2_fwd : id_ex_q.imm),
    .alu_fct3(id_ex_q.ex.alu_fct3),

    .alu_out(ex_mem_d.alu_out)
);

branch_unit branch_unit(
    .alu_out(ex_mem_d.alu_out),
    .fct3(id_ex_q.ex.fct3),

    .br(br)
);

WB_sel_mux WB_sel_mux(
    .alu(ex_mem_d.alu_out),
    .pc(ex_mem_d.pc),
    .op_class(ex_mem_d.op_class),  //cu
    .ta(ex_mem_d.ta),

    .WBval(ex_mem_d.WBval)
);

endmodule