import riscv_pkg::*;
module alu( 
    input logic [31:0] val1,
    input logic [31:0] val2,
    input logic ALU_fct3,

    output logic alu_out,
    output logic br
);
    logic [4:0] shamt;
    assign shamt = val2; // decided to use shamt because I believe that is convention

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

            //Break Functions
            ALU_BEQ     : br = val1 == val2;
            ALU_BNE     : br = val1 != val2;
            ALU_BLT     : br = ($signed(val1) < $signed(val2));
            ALU_BGE     : br = ($signed(val1) >= $signed(val2)); 
            ALU_BLTU    : br = val1 < val2;
            ALU_BGEU    : br = val1 >= val2;
            
            
            HOLD        : alu_out = 32'b0;
            default: alu_out = 32'b0;
        endcase
        
    end





endmodule