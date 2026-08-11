module reg_file(
    input logic clk,
    
    input logic we,
    input logic [4:0] S2reg,
    input logic [4:0] S1reg,
    input logic [31:0] WBval,
    input logic [4:0] WBreg,

    output logic [31:0] S1val,
    output logic [31:0] S2val

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