`default_nettype none //prevents me from forgetting to declare a wire
import riscv_pkg::*;
module top_lvl(
    input wire clk,
    input wire rst_n
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
logic [31:0] id_S1val;
logic [31:0] id_S2val;

fwd_sel_t fwd_a;
fwd_sel_t fwd_b;

logic load_use_hazard;

assign load_use_hazard = (id_ex_q.op_class == LOAD && id_ex_q.wb.rd != 0 && ((id_ex_q.wb.rd == if_id_q.inst[19:15]) || (id_ex_q.wb.rd == if_id_q.inst[24:20])));
assign stall_if = load_use_hazard;

stage_if stage_if(
    .clk(clk),
    .rst_n(rst_n),

    .stall(stall_if),
    .ex_redirect(ex_redirect),
    .ex_redirect_pc(ex_redirect_pc),

    .if_id_d(if_id_d)
);

assign flush_id = ex_redirect; 
assign stall_id = load_use_hazard;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)          if_id_q <= '0;
    else if (flush_id)   if_id_q <= '0;
    else if (!stall_id)  if_id_q <= if_id_d;
end


reg_file reg_file(
    .clk(clk),
    
    .we(mem_wb_q.wb.we_reg),            //comes back in from wb stage
    .S2reg(if_id_q.inst[24:20]),
    .S1reg(if_id_q.inst[19:15]),
    .WBval(mem_wb_q.WBval),                      //comes back in from wb stage
    .WBreg(mem_wb_q.wb.rd),             //comes back in from wb stage

    .S1val(id_S1val),   //fed back into stage_id so that the total output comes from stage_id
    .S2val(id_S2val)  //fed back into stage_id so that the total output comes from stage_id
);

stage_id stage_id(
    .if_id_q(if_id_q),
    .S1val(id_S1val),
    .S2val(id_S2val),
    
    .id_ex_d(id_ex_d)
);

assign flush_ex = ex_redirect || load_use_hazard;
assign stall_ex = 1'b0; //waiting on M extenstion


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)          id_ex_q <= '0;
    else if (flush_ex)   id_ex_q <= '0;
    else if (!stall_ex)  id_ex_q <= id_ex_d;
end

forwarding_unit forwarding_unit(
    .id_S1reg(id_ex_q.rs1),
    .id_S2reg(id_ex_q.rs2),

    .ex_WBreg(ex_mem_q.wb.rd),
    .ex_we(ex_mem_q.wb.we_reg),

    .mem_WBreg(mem_wb_q.wb.rd),
    .mem_we(mem_wb_q.wb.we_reg),

    .fwd_a(fwd_a),
    .fwd_b(fwd_b)
);

stage_ex stage_ex(
    .id_ex_q(id_ex_q),
    .fwd_ex_val(ex_mem_q.WBval),
    .fwd_mem_val(mem_wb_q.WBval),
    .fwd_a(fwd_a), 
    .fwd_b(fwd_b),

    .ex_mem_d(ex_mem_d),
    .ex_redirect(ex_redirect),//not pipelined
    .ex_redirect_pc(ex_redirect_pc) //not pipelined
);

assign flush_mem = 1'b0; //implemented at L5
assign stall_mem = 1'b0; //implemented at L4

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)          ex_mem_q <= '0;
    else if (flush_mem)   ex_mem_q <= '0;
    else if (!stall_mem)  ex_mem_q <= ex_mem_d;
end

stage_mem stage_mem(
    .clk(clk),
    .ex_mem_q(ex_mem_q),

    .mem_wb_d(mem_wb_d)
);

assign flush_wb = 1'b0; //implemented at L4
assign stall_wb = 1'b0; // WB never stalls: nothing downstream can block it

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)          mem_wb_q <= '0;
    else if (flush_wb)   mem_wb_q <= '0;
    else if (!stall_wb)  mem_wb_q <= mem_wb_d;
end


endmodule