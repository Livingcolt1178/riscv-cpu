import riscv_pkg::*;
module stage_wb (
    input mem_wb_t mem_wb_q,

    output logic [31:0] WBval
);

    always_comb begin
        if(mem_wb_q.op_class == LOAD) begin
            WBval = mem_wb_q.mem_out;
        end else begin
            WBval = mem_wb_q.WBval;
        end
    end
endmodule