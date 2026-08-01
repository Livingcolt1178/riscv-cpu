module alu_control_unit (
input logic [2:0] fct3,
input logic alu_modifier,
input logic [3:0] action, //this will be what tells the ALU what type of action we are doing, whether it be a simple ALU, branch, or Jump. action 2 is reserved for memory for WB_sel_mux

output ALU_fct3_T ALU_fct3

);

    always_comb begin 
        if(action == 1) begin   //ALU
            case(fct3)
                000: if( alu_modifier == 0) begin
                    ALU_fct3 = ALU_ADD;
                end else begin
                    ALU_fct3 = ALU_SUB;
                end
                001: ALU_fct3 = ALU_SLL;
                010: ALU_fct3 = ALU_SLT;
                011: ALU_fct3 = ALU_SLTU;
                100: ALU_fct3 = ALU_XOR;
                101: if( alu_modifier == 0) begin
                    ALU_fct3 = ALU_SRL;
                end else begin
                    ALU_fct3 = ALU_SRA;
                end
                110: ALU_fct3 = ALU_OR;
                111: ALU_fct3 = ALU_AND;
                default : ALU_fct3 = HOLD;
            endcase
        end else if (action == 2) begin     //load and store
            ALU_fct3 = ALU_ADD;
        end else if (action == 3) begin //branch
            case(fct3)
                000: ALU_fct3 = ALU_BEQ;
                001: ALU_fct3 = ALU_BNE;
                100: ALU_fct3 = ALU_BLT;
                101: ALU_fct3 = ALU_BGE;
                110: ALU_fct3 = ALU_BLTU;
                111: ALU_fct3 = ALU_BGEU;
                default : ALU_fct3 = HOLD;
            endcase
        end else if (action == 4) begin     //jump
            ALU_fct3 = ALU_ADD;
        end else begin
            ALU_fct3 = HOLD;
        end
    end



endmodule