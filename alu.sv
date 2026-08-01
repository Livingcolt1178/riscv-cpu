import riscv_pkg::*;
module alu( 
    input logic [31:0] val1,
    input logic [31:0] val2,
    input ALU_fct3_t ALU_fct3,

    output logic [31:0] alu_out
);
    logic [4:0] shamt;
    assign shamt = val2 [4:0]; // decided to use shamt because I believe that is convention

    // Function of ALU
    always_comb begin
        case(ALU_fct3)
            ALU_ADD     : alu_out = val1 + val2;
            ALU_SUB     : alu_out = val1 - val2;
            ALU_SLL     : alu_out = val1 << shamt;
            ALU_SLT     : alu_out = ($signed(val1) < $signed(val2)) ? 32'd1 : 32'd0; //this checks iif val1 is less than val 2 if true it sets output to 1.
            ALU_SLTU    : alu_out = (val1 < val2) ? 32'd1 : 32'd0; 
            ALU_XOR     : alu_out = val1 ^ val2;
            ALU_SRL     : alu_out = val1 >> shamt;
            ALU_SRA     : alu_out = $signed(val1) >> shamt; //this preserves the sign, logical merely fills it with zeros.
            ALU_OR      : alu_out = val1 | val2;
            ALU_AND     : alu_out = val1 & val2;           
            
            default: alu_out = '0;
        endcase
    end
endmodule