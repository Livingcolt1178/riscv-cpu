import riscv_pkg::*;
module pc(
    input logic clk,
    input logic rst_n,

    input logic stall,
    input logic ex_redirect,
    input logic [31:0] ex_redirect_pc,

    output logic [31:0] pc_out
);

    logic [31:0] pc_next;


    always_comb begin
        if(ex_redirect) begin
            pc_next = ex_redirect_pc;
        end else begin
            pc_next = pc_out + 32'd4;;
        end
    end

    always_ff @(posedge clk) begin : blockName
        if (!rst_n) begin
            pc_out <= 32'h8000_0000; 
        end else if(stall) begin
            pc_out <= pc_out;
        end else begin
            pc_out <= pc_next;
        end
    end
endmodule