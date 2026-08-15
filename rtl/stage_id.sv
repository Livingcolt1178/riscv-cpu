import riscv_pkg::*;
module stage_id (
    input if_id_t if_id_q,
    input logic [31:0] S1val,
    input logic [31:0] S2val,

    output id_ex_t id_ex_d
);

format_t format;
logic alu_modifier;

assign id_ex_d.valid    = if_id_q.valid;
assign id_ex_d.pc       = if_id_q.pc;
assign id_ex_d.ex.fct3  = if_id_q.inst[14:12];
assign id_ex_d.mem.fct3 = if_id_q.inst[14:12];
assign id_ex_d.wb.rd    = if_id_q.inst[11:7];
assign id_ex_d.S1val    = S1val;
assign id_ex_d.S2val    = S2val;
assign id_ex_d.rs1      = if_id_q.inst[19:15];  //used in forwarding
assign id_ex_d.rs2      = if_id_q.inst[24:20];  //used in forwarding

//trace signals
assign id_ex_d.inst     = if_id_q.inst;


build_imm build_imm(
    .inst(if_id_q.inst),    
    .format(format),        //internal
    
    .imm(id_ex_d.imm)       
);

alu_control_unit alu_control_unit (
    .fct3(if_id_q.inst[14:12]),        
    .alu_modifier(alu_modifier), //cu
    .op_class(id_ex_d.op_class),
    .format(format),

    .alu_fct3(id_ex_d.ex.alu_fct3)
);

control_unit control_unit(
    .fct7(if_id_q.inst[31:25]),
    .opcode(if_id_q.inst[6:0]),

    .op_class(id_ex_d.op_class),
    .alu_modifier(alu_modifier),//internal
    .we_mem(id_ex_d.mem.we_mem),
    .we_reg(id_ex_d.wb.we_reg),
    .format(format),//internal
    .alu_s2_ctrl(id_ex_d.ex.alu_s2_ctrl)
);
endmodule



        