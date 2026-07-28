module alu( 
    input logic [31:0] val1,
    input logic [31:0] val2,
    input logic [2:0] fct3,
    input logic alu_modifier,

    output logic alu_out,
    output logic br
);
    logic [4:0] shamt;
    assign shamt = val2; // decided to use shamt because I believe that is convention

    always_comb begin
        case(fct3)
            000 :   begin
                        if(alu_modifier) begin
                            alu_out = val1 - val2;
                        end else begin
                            alu_out = val1 + val2;
                        end
                    end
            001 : alu_out = val1 << shamt;
            010 : alu_out = ($signed(val1) < $signed(val2)) ? 32'd1 : 32'd0; //this checks iif val1 is less than val 2 if true it sets output to 1.
            011 : alu_out = (val1 < val2) ? 32'd1 : 32'd0; 
            100 : alu_out = val1 ^ val2;
            101 :   begin
                        if(alu_modifier) begin
                            alu_out = $signed(val1) >> shamt; //this preserves the sign, logical merely fills it with zeros.
                        end else begin
                            alu_out = val1 >> shamt;
                        end
                    end
            110 : alu_out = val1 | val2;
            111 : alu_out = val1 & val2;
            default: alu_out = 32'd0;
        endcase
        
    end





endmodule