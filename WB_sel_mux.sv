module WB_sel_mux(
    input logic [31:0] alu,
    input logic [31:0] mem,
    input logic [31:0] pc_plus4,
    input logic [2:0]  action,

    output logic [31:0] WBval
);

always_comb begin
    case(action)
        1 : WBval = alu;
        2 : WBval = mem;
        4 : WBval = pc_plus4;
        default WBval = alu;
    endcase
end


endmodule