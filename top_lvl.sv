`default_nettype none //prevents me from forgetting to declare a wire
import riscv_pkg::*;
module top_lvl(
    input wire clk,
    input wire rst_n
);
logic [31:0] pc_out;
logic [31:0] pc_plus4;

logic [31:0] inst;
logic [31:0] imm;

logic [6:0] opcode;
logic [4:0] rd;
logic [2:0] fct3;
logic [4:0] rs1;
logic [4:0] rs2;
logic [6:0] fct7;

logic [31:0] S1val;
logic [31:0] S2val;
logic [31:0] WBval;
logic [31:0] alu_out;
logic [31:0] mem_out;
logic [31:0] alu_s2;
logic br;
logic [31:0] ta;
logic we_mem;
logic we_reg;
logic alu_modifier;


op_class_t op_class;
format_t format;
ALU_fct3_t ALU_fct3;

assign alu_s2 = (format == R || format == B ? S2val : imm); // this is alu src mux

control_unit control_unit(
    .fct7(fct7),
    .opcode(opcode),

    .op_class(op_class),
    .alu_modifier(alu_modifier),
    .we_mem(we_mem),
    .we_reg(we_reg),
    .format(format)
);

pc pc (
    .clk(clk),
    .rst_n(rst_n),

    .br(br),
    .ta(ta),
    .op_class(op_class),

    .pc_out(pc_out),
    .pc_plus4(pc_plus4)
    );

target_address_constructor target_address_constructor(
        .imm(imm),
        .pc(pc_out),
        .rs1(rs1),
        .op_class(op_class),
        
        .ta(ta)
    );

ir ir(
    .clk(clk),
    .rst_n(rst_n),
    .inst(inst),

    .opcode(opcode),    //to cu
    .rd(rd),
    .fct3(fct3),    
    .rs1(rs1),
    .rs2(rs2),
    .fct7(fct7)
);

alu_control_unit alu_control_unit (
    .fct3(fct3),        
    .alu_modifier(alu_modifier), //cu
    .op_class(op_class),
    .format(format),

    .ALU_fct3(ALU_fct3)
);

alu alu(
    .val1(S1val),
    .val2(alu_s2),
    .ALU_fct3(ALU_fct3),

    .alu_out(alu_out)
);

branch_unit branch_unit(
    .alu_out(alu_out),
    .fct3(fct3),

    .br(br)
);

WB_sel_mux WB_sel_mux(
    .alu(alu_out),
    .mem(mem_out),
    .pc_plus4(pc_plus4),
    .op_class(op_class),  //cu
    .ta(ta),

    .WBval(WBval)
);

reg_file reg_file(
    .clk(clk),
    
    .we(we_reg),      //cu
    .S2reg(rs2),
    .S1reg(rs1),
    .WBval(WBval),
    .WBreg(rd),

    .S2val(S2val),
    .S1val(S1val)

);

instruction_cache instruction_cache(
    .pc(pc_out),

    .inst(inst)
);

data_cache data_cache(
    .clk(clk),

    .addr(alu_out),
    .mem_in(S2val),
    .we(we_mem),      //cu

    .mem_out(mem_out)
);

build_imm build_imm(
    .inst(inst),
    .format(format),

    .imm(imm)
);



endmodule