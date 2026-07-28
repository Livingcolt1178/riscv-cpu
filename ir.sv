module ir(
    input logic clk,
    input logic rst_n,
    input logic [31:0] inst,

    output logic [6:0] opcode,
    output logic [4:0] rd,
    output logic [2:0] fct3,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [6:0] fct7
);

always_ff (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        opcode  <= 0;
        rd      <= 0;
        fct3    <= 0;
        rs1     <= 0;
        rs2     <= 0;
        fct7    <= 0;
    end else begin
        opcode  <= inst [6:0];
        rd      <= inst [11:7];
        fct3    <= inst [14:12];
        rs1     <= inst [19:15];
        rs2     <= inst [24:20];
        fct7    <= inst [31:25];
    end
end

    
    

endmodule