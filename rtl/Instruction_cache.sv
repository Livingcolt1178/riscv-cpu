module instruction_cache(
    input logic [31:0] pc,

    output logic [31:0] inst
);
    localparam DEPTH = 1024;
    logic [31:0] regs [DEPTH-1:0];

    initial $readmemh("program.hex", regs); // this initalizes the instruction cache with the program.

    // the reason for $clog2(DEPTH)+1, is because we are masking the high pc, spike requires a high pc, but the ic doesn't support that, so instead we cut out the bits above what the pc can handle keeping it inline, this requires an assertion though to make sure that its not a silent fail.
    assign inst = regs[pc[$clog2(DEPTH)+1:2]];

endmodule