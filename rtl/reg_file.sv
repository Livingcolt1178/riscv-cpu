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

//important note, because we are now dealing with mulitple cycles, if we are reading from the same register we are writing to, because writing is register clked and reding is combination, it would be reading an old value. thus we need to implement write first bypass, which eseintally connects the write to the read port combinationally if rd and write reg are to same so as to not read a stale value.

    logic [31:0] regs [31:0];
    logic wr_en;

    assign wr_en = (we && WBreg != 0)
    always_comb begin
        if((wr_en) && WBreg == S1reg) begin         //can be read as if a write is happening at the same place as read
            S1val = WBval;
        end else begin
            S1val = (S1reg == 0) ? 0 : regs[S1reg];
        end
        if((wr_en) && WBreg == S2reg) begin
            S2val = WBval;
        end else begin
            S2val = (S2reg == 0) ? 0 : regs[S2reg];
        end
    end


    always_ff @(posedge clk) begin
        if(wr_en) begin
            regs[WBreg] <= WBval;
        end 
    end

endmodule