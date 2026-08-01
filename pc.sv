import riscv_pkg::*;
module pc(
    input logic clk,
    input logic rst_n,

    input logic br,
    input logic [31:0] ta,
    input op_class_t op_class,

    output logic [31:0] pc_out,
    output logic [31:0] pc_plus4
);

    logic [31:0] pc_next;

    assign pc_plus4   = pc_out + 4;     

    always_comb begin
        case(op_class)
            BRANCH:  pc_next = (br == 1 ) ? ta : pc_plus4;
            JUMP:  pc_next = ta;
            JUMPR: pc_next = {ta[31:1], 1'b0};
            default: pc_next = pc_plus4;
        endcase
    end

    always_ff @( posedge clk or negedge rst_n) begin : blockName
        if (!rst_n) begin
            pc_out <= 0; 
        end else begin
            pc_out <= pc_next;
        end
    end
endmodule