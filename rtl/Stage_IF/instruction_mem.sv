`timescale 1ns/1ps
module instruction_mem
import riscv_pkg::*;
(
    input logic clk_i,
    input logic stall_i,
    input logic [31:0] pc_i,

    output logic [31:0] inst_o
);
    localparam int unsigned DEPTH = 512;
    logic [31:0] inst_q;

    (* rom_style = "block" *) logic [31:0] regs [DEPTH];

    initial $readmemh(INIT_FILE, regs); // this initalizes the instruction cache with the program.

    // the reason for $clog2(DEPTH)+1, is because we are masking the high pc, spike requires a high pc,
    // but the ic doesn't support that, so instead we cut out the bits above what the pc can handle keeping
    // it inline, this requires an assertion though to make sure that its not a silent fail.
    always_ff @(posedge clk_i) begin
        if(!stall_i) begin
            inst_q <= regs[pc_i[$clog2(DEPTH)+1:2]];
        end
    end

    assign inst_o = inst_q;

endmodule
