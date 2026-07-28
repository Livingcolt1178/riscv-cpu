module WB_sel_mux(
    input logic [31:0] alu,
    input logic [31:0] mem,
    input logic [31:0] pc_plus4,
    input logic [2:0]  action,

    output logic [31:0] WB_value
);

always_comb begin
    case(action)
        1 : WB_value = alu;
        2 : WB_value = mem;
        3 : WB_value = pc_plus4;
    endcase
end


endmodule