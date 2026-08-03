module data_cache #(parameter int DEPTH = 256) (
    input logic clk,
    
    input logic [31:0] addr,        //passes full addr in
    input logic [31:0] mem_in,
    input logic we,

    output logic [31:0] mem_out 
);
    logic [7:0] byte_data;
    logic [15:0] half_data;
    logic [31:0] word_data;

    logic [31:0] regs [DEPTH-1:0];
    logic [$clog2(DEPTH)-1:0] word_addr;
    assign lane = addr[1:0]; //this gives us the byte in the word we are looking at
    assign start = lane << 3;
    assign word_addr = addr[$clog2(DEPTH)+1:2]; //slices it to fit the addres width
    /* Brainstorm box

    alright so I can't smoothly just look forward as if its a giant line of bits because its word organized. Because its byte addresable, 
    that means I need to first find the word we are looking at, and then further divide down to byte of that word we are looking at. 
    This is important for Store mostly because if we just thrown in that can overwrite other bytes in the word we may not want to. 
    Additonally we need to figure out how to deal with cross word orders/misaligned orders, for example a store word that addresed to a byte in the middle of the word.

    */

    
    //Load handeling
    always_comb begin
            case(fct3) 
                3'b000: mem_out = $signed(regs[word_addr][start +: 8]);
                3'b001: mem_out = $signed(regs[word_addr][start +: 16]); // need to deal with alignment
                3'b010: mem_out = regs [word_addr];

                3'b100: mem_out = regs[word_addr][start +: 8];
                1'b101: mem_out = regs[word_addr][start +: 16]; // need to deal with alignment
                default: mem_out = 32'b0;
            endcase
    end
    
    
    
    //Store Handeling
    assign byte_data = mem_in [7:0];
    assign half_data = mem_in [15:0];
    assign word_data = mem_in;    

    always_ff @(posedge clk) begin
        if(we) begin

        if(op_class == STORE) begin
            case(fct3) 
                3'b000: regs[addr[word_addr]] <= byte_data;
                3'b001: regs[addr[word_addr]] <= half_data;
                3'b010: regs[addr[word_addr]] <= word_data;
            endcase
        end
            
        end
    end
endmodule