module top_lvl();
// todo: control unit, wire top_lvl, create package.
logic clk;
logic rst_n;


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
assign alu_s2 = (opcode == 0110011 ? S2val : imm); // this is alu src mux

pc pc (
    .clk(clk),
    .rst_n(rst_n),

    .br(),
    .imm(imm),

    .pc_out(pc_out),
    .pc_plus4(pc_plus4)
    );

ir ir(
    .clk(clk),
    .rst_n(rst_n),
    .inst(inst),

    .opcode(opcode),    //to cu
    .rd(rd),
    .fct3(fct3),    //dunno yet
    .rs1(rs1),
    .rs2(rs2),
    .fct7(fct7)
);


alu alu(
    .val1(S1val),
    .val2(alu_s2),
    .fct3(fct3),        //not sure
    .alu_modifier(alu_modifier),      //cu
    
    .alu_out(alu_out),
    .br()           //not sure yet
);

WB_sel_mux WB_sel_mux(
    .alu(alu_out),
    .mem(mem_out),
    .pc_plus4(pc_plus4),
    .action(action),  //cu

    .WBval(WBval)
);

reg_file reg_file(
    .clk(clk),
    
    .we(we),      //cu
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
    .we(we),      //cu

    .me_out(mem_out)
);

build_imm build_imm(
    .inst(inst),
    .format(format),

    .imm(imm)
);



endmodule