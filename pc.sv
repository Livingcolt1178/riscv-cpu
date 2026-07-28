module pc(
    input logic clk,
    input logic rst_n,

    input logic br,
    input logic [31:0] imm,

    output logic [31:0] pc_out
    output logic [31:0] pc_plus4;
);

    logic [31:0] pc_branch;
    logic [31:0] pc_next;

    assign pc_branch  = pc_out + imm;   // TA adder
    assign pc_plus4   = pc_out + 4;     
    assign pc_next    = br ? pc_branch : pc_plus4; //pc src mux

    always_ff @( posedge clk or negedge rst_n) begin : blockName
        if (!rst_n) begin
            pc_out <= 0;
        end else begin
            pc_out <= pc_next;
        end
    end
endmodule