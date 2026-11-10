`timescale 1ns/1ps
module forwarding_unit
import riscv_pkg::*;
(
    input logic [4:0] id_rs1_addr_i,
    input logic [4:0] id_rs2_addr_i,

    input logic ex_valid_i,
    input logic [4:0] ex_wb_addr_i,
    input logic ex_we_i,

    input logic mem_valid_i,
    input logic [4:0] mem_wb_addr_i,
    input logic mem_we_i,

    output fwd_sel_t fwd_a_o,
    output fwd_sel_t fwd_b_o
);

logic ex_hit_a, ex_hit_b, valid_ex_write;
logic mem_hit_a, mem_hit_b, valid_mem_write;
//we need id request
//ex wren and deposit
//mem wren and deposit
    assign valid_ex_write  = ex_valid_i &&  ex_we_i &&  (ex_wb_addr_i != 0);
    assign valid_mem_write = mem_valid_i && mem_we_i && (mem_wb_addr_i != 0);

    assign  ex_hit_a =  valid_ex_write &&  (ex_wb_addr_i == id_rs1_addr_i);
    assign mem_hit_a = valid_mem_write && (mem_wb_addr_i == id_rs1_addr_i);

    assign  ex_hit_b =  valid_ex_write &&  (ex_wb_addr_i == id_rs2_addr_i);
    assign mem_hit_b = valid_mem_write && (mem_wb_addr_i == id_rs2_addr_i);

    always_comb begin
            fwd_a_o = FwdNone;
            fwd_b_o = FwdNone;
        if(ex_hit_a) begin
            fwd_a_o = FwdEx;
        end else if(mem_hit_a) begin
            fwd_a_o = FwdMem;
        end else begin
            fwd_a_o = FwdNone;
        end

        if(ex_hit_b) begin
            fwd_b_o = FwdEx;
        end else if (mem_hit_b) begin
            fwd_b_o = FwdMem;
        end else begin
            fwd_b_o = FwdNone;
        end
    end
endmodule
