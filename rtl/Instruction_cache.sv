module instruction_cache(
    input logic [31:0] pc,

    output logic [31:0] inst
);
    localparam DEPTH = 256;
    logic [31:0] regs [DEPTH-1:0];

    initial $readmemh("program.hex", regs); // this initalizes the instruction cache with the program.

    assign inst = regs[pc[31:2]];

endmodule