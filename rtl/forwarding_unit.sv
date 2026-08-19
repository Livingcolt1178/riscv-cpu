import riscv_pkg::*;

module forwarding_unit (
    input logic [4:0] id_S1reg,
    input logic [4:0] id_S2reg,

    input logic ex_valid,
    input logic [4:0] ex_WBreg,
    input logic ex_we,

    input logic mem_valid,
    input logic [4:0] mem_WBreg,
    input logic mem_we,

    output fwd_sel_t fwd_a,
    output fwd_sel_t fwd_b
);

logic ex_hit_a;
logic mem_hit_a;
logic ex_hit_b;
logic mem_hit_b;
//we need id request
//ex wren and deposit
//mem wren and deposit
    assign  ex_hit_a =  ex_valid && ex_we &&  ex_WBreg != 0 &&  ex_WBreg == id_S1reg;
    assign mem_hit_a =  mem_valid && mem_we && mem_WBreg != 0 && mem_WBreg == id_S1reg;

    assign  ex_hit_b =  ex_valid && ex_we &&  ex_WBreg != 0 &&  ex_WBreg == id_S2reg;
    assign mem_hit_b =  mem_valid && mem_we && mem_WBreg != 0 && mem_WBreg == id_S2reg;

    always_comb begin
            fwd_a = FWD_NONE;
            fwd_b = FWD_NONE;
        if(ex_hit_a) begin
            fwd_a = FWD_EX;
        end else if(mem_hit_a) begin
            fwd_a = FWD_MEM;
        end else begin
            fwd_a = FWD_NONE;
        end

        if(ex_hit_b) begin
            fwd_b = FWD_EX;
        end else if (mem_hit_b) begin
            fwd_b = FWD_MEM;
        end else begin
            fwd_b = FWD_NONE;
        end
                   
    end
endmodule        



