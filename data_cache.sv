module data_cache(
    input logic clk,
    
    input logic [31:0] addr,
    input logic [31:0] mem_in,
    input logic we,

    output logic [31:0] mem_out 
);
    localparam DEPTH = 256;
    logic [31:0] regs [DEPTH-1:0];
    assign mem_out = regs[addr[31:2]];

    always_ff @(posedge clk) begin
        if(we) begin
            regs[addr[31:2]] <= mem_in;
        end
    end
endmodule