module stage_wb(
input mem_wb_t mem_wb_q,
input logic [31:0] dmem_in,

output logic [31:0] WBval
);

logic [31:0] shifted_data;
logic [31:0] wb_data;

assign shifted_data = dmem_in >> (8*mem_wb_q.wb.lane);

always_comb begin
    case(mem_wb_q.wb.fct3) 
        3'b000: wb_data = {{24{shifted_data[7]}}, shifted_data[7:0]};  //LB
        3'b001: wb_data = {{16{shifted_data[15]}},shifted_data[15:0]}; //LH
        3'b010: wb_data = shifted_data;                                //LW

        3'b100: wb_data = {24'b0,shifted_data[7:0]};                //LBU
        3'b101: wb_data = {16'b0,shifted_data[15:0]};               //LHU
        default: wb_data = '0;
    endcase

end

assign WBval = (mem_wb_q.op_class == LOAD) ? wb_data : mem_wb_q.temp_WBval;

endmodule