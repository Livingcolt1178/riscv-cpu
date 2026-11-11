`timescale 1ns/1ps
module data_mem
import riscv_pkg::*;
#(parameter int DEPTH = 512) (
    input logic clk_i,

    input logic valid_i,
    input logic [31:0] addr_i,        //passes full addr in
    input logic [31:0] mem_i,
    input logic [2:0] fct3_i,
    input logic we_i,

    output logic [31:0] dmem_o
);
    logic [1:0] lane;
    logic [3:0] be; //byte enable
    logic [31:0] wdata, dmem_q;

    (* ram_style = "block" *) logic [31:0] regs[DEPTH];
    logic [$clog2(DEPTH)-1:0] word_addr;

    assign lane = addr_i[1:0]; //this gives us the byte in the word we are looking at
    assign word_addr = addr_i[$clog2(DEPTH)+1:2]; //slices it to fit the addres width
    /* Brainstorm box

        alright so I can't smoothly just look forward as if its a giant line of bits because its word organized. Because its byte addresable,
        that means I need to first find the word we are looking at, and then further divide down to byte of that word we are looking at.
        This is important for Store mostly because if we just thrown in that can overwrite other bytes in the word we may not want to.
        Additonally we need to figure out how to deal with cross word orders/misaligned orders, for example a store word that addresed
        to a byte in the middle of the word.
    */

    /*
        when considering how to implement byte enable masks, we need to ask, do we shift the data or duplicate it.
        I will be going with duplication, because fct3 is already passed in, and should be ~12 less LUTS and would scale better.
    */

    //Store Handeling
    //duplication
    always_comb begin
        unique case(fct3_i[1:0])
            //byte operation, duplicates the first byte too the other 3 bytes
            2'b00: wdata = {4{mem_i [7:0]}};
            //half operation, duplicates the first 2 byte too the other 2 bytes
            2'b01: wdata = {2{mem_i [15:0]}};
            //word operation, just passes through
            2'b10: wdata = mem_i;
            default wdata = '0;
        endcase
    end

    //byte enable mask
    always_comb begin
        unique case(fct3_i[1:0])
            2'b00:      be = 4'b0001 << lane;   //byte operation
            2'b01:      be = 4'b0011 << lane;   //half operation
            2'b10:      be = 4'b1111;           //word operation, all enabled
            default:    be = 4'b0000;
        endcase
        be = be & {4{we_i}};
    end

    always_ff @(posedge clk_i) begin
        if(valid_i)begin
            //store operations
            if (be[0]) regs[word_addr][7:0]   <= wdata[7:0];
            if (be[1]) regs[word_addr][15:8]  <= wdata[15:8];
            if (be[2]) regs[word_addr][23:16] <= wdata[23:16];
            if (be[3]) regs[word_addr][31:24] <= wdata[31:24];

            //load operations
            dmem_q <= regs[word_addr];
        end
    end
    assign dmem_o = dmem_q;
endmodule
