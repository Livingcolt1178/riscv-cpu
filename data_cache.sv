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
    logic [$clog2(DEPTH)-1:0] byte_addr;
    assign byte_addr = addr[$clog2(DEPTH)+1:2]; //slices it to fit the addres width
    
    
    //Load handeling
    assign mem_out = regs[addr[byte_addr]];     
    always_comb begin
            case(fct3) 
                3'b000: mem_out = $signed(regs[addr[byte_addr + 8: byte_addr]]);
                3'b001: mem_out = $signed(regs[addr[byte_addr + 16: byte_addr]]);
                3'b010: mem_out = $signed(regs[addr[byte_addr + 32: byte_addr]]);

                3'b100: mem_out = {24'b0,regs[addr[byte_addr + 8: byte_addr]]};
                3'b101: mem_out = {16'b0,regs[addr[byte_addr + 16: byte_addr]]};
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
                3'b000: regs[addr[byte_addr]] <= byte_data;
                3'b001: regs[addr[byte_addr]] <= half_data;
                3'b010: regs[addr[byte_addr]] <= word_data;
            endcase
        end
            
        end
    end
endmodule