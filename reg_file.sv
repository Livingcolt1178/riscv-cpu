module reg_file(
    input logic clk,
    
    input logic we,
    input logic S2reg,
    input logic S1reg,
    input logic WBval,
    input logic WBreg,

    output logic S2val,
    output logic S1val
);

    logic [31:0] regs [31:0];

    assign S1val = (S1reg == 0) ? 0 : regs[S1reg];
    assign S2val = (S2reg == 0) ? 0 : regs[S2reg];

    always_ff @(posedge clk) begin
        if(we && WBreg != 0) begin
            regs[WBreg] <= WBval;
        end 
    end

endmodule