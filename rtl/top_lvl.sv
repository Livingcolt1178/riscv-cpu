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

logic stall_id;
logic stall_ex;
logic stall_mem;
logic stall_wb;

logic flush_id;
logic flush_ex;
logic flush_mem;
logic flush_wb;

logic [31:0] wb_WBval;
logic ex_redirect;
logic [31:0] ex_redirect_pc;
logic [31:0] id_S1val;
logic [31:0] id_S2val;

stage_if stage_if(
    .clk(clk),
    .rst_n(rst_n),

    .ex_redirect(ex_redirect),
    .ex_redirect_pc(ex_redirect_pc),

    .if_id_d(if_id_d)
);

assign flush_id = 1'b0; //ex_redirect at L3b
assign stall_id = 1'b0; //load-use interlock implemented at L3b

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
    .WBval(wb_WBval),                      //comes back in from wb stage
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

assign flush_ex = 1'b0; //ex_redirect at L3b
assign stall_ex = 1'b0; //waiting on M extenstion


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)          id_ex_q <= '0;
    else if (flush_ex)   id_ex_q <= '0;
    else if (!stall_ex)  id_ex_q <= id_ex_d;
end

stage_ex stage_ex(
    .id_ex_q(id_ex_q),

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

stage_wb stage_wb(
    .mem_wb_q(mem_wb_q),

    .WBval(wb_WBval)
);

endmodule