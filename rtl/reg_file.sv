`timescale 1ns/1ps
module reg_file(
    input logic clk_i,

    input logic valid_i,
    input logic we_i,
    input logic [4:0] rs1_addr_i,
    input logic [4:0] rs2_addr_i,
    input logic [31:0] wb_data_i,
    input logic [4:0] wb_addr_i,

    output logic [31:0] rs1_data_o,
    output logic [31:0] rs2_data_o
);

//important note, because we are now dealing with mulitple cycles, if we are reading from the same register we are writing to, because writing is register clked and reding is combination, it would be reading an old value. thus we need to implement write first bypass, which eseintally connects the write to the read port combinationally if rd and write reg are to same so as to not read a stale value.

    logic [31:0] regs[32];
    logic wr_en;

    assign wr_en = (we_i && wb_addr_i != 0 && valid_i);

    always_comb begin
        //can be read as if a write is happening at the same place as read
        if((wr_en) && wb_addr_i == rs1_addr_i) begin
            rs1_data_o = wb_data_i;
        end else begin
            rs1_data_o =  (rs1_addr_i == 0) ? 0 : regs[rs1_addr_i];
        end

        if((wr_en) && wb_addr_i == rs2_addr_i) begin
            rs2_data_o = wb_data_i;
        end else begin
            rs2_data_o = (rs2_addr_i == 0) ? 0 : regs[rs2_addr_i];
        end
    end


    always_ff @(posedge clk_i) begin
        if(wr_en) begin
            regs[wb_addr_i] <= wb_data_i;
        end
    end
endmodule
