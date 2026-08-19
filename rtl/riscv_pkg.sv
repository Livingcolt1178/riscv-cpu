package riscv_pkg;

    parameter string INIT_FILE = "C:/Users/nrbra/Projects/RISC-V/riscv-cpu/build/program.hex";
    parameter int TOHOST = 32'h8000_13F0;       //do not forget to compare against link.ld

    typedef enum logic [2:0] {
        R,
        I,
        S,
        B,
        U,
        J
    } format_t;

    typedef enum logic [3:0] {
            ALU_ADD,
            ALU_SUB,
            ALU_SLL,
            ALU_SLT,
            ALU_SLTU, 
            ALU_XOR,   
            ALU_SRL,     
            ALU_SRA,
            ALU_OR,
            ALU_AND
    } alu_fct3_t;

    typedef enum logic [3:0] {
            NOP,

            ALU,
            LOAD,
            STORE,
            BRANCH,
            JUMP,
            JUMPR,
            LUI,
            AUIPC,
            FENCE   //not yet implemented
    } op_class_t;

    typedef enum logic [1:0] {
        FWD_NONE,
        FWD_EX,
        FWD_MEM
    } fwd_sel_t;

    typedef struct packed {
        alu_fct3_t alu_fct3;
        logic alu_s2_ctrl;
        logic [2:0] fct3;
    } ex_ctrl_t;

    typedef struct packed {
        logic we_mem;
        logic [2:0] fct3;
    } mem_ctrl_t;

    typedef struct packed {
        logic we_reg;   //need this because the wbvalue must get passed back in due to reg file straddleing id and wb.
        logic [4:0] rd;
        logic [1:0] lane;
        logic [2:0] fct3;
    } wb_ctrl_t;

    typedef struct packed {
        logic [31:0] inst, alu_out, mem_wdata, pc;
        logic [2:0] fct3;
    } trace_t;

    typedef struct packed {
        logic valid;
        logic [31:0] pc;

    } if_id_t;
    
    typedef struct packed {
        logic valid;
        logic [31:0] pc;         //dies in ex 
        logic [31:0] inst;       //carried for verification
        logic [31:0] imm, S1val; //dies in ex
        logic [31:0] S2val;      //dies in mem
        logic [4:0] rs1, rs2;    //dies in ex, used for forwarding
        op_class_t op_class;     //dies in mem
        ex_ctrl_t ex;            //dies in ex
        mem_ctrl_t mem;          //dies in mem
        wb_ctrl_t wb;            //dies in wb
    } id_ex_t;

    typedef struct packed {
        logic valid;
        logic [31:0] pc, inst, alu_out;              //carried for verification
        logic [31:0] S2val;  //dies in mem
        logic [31:0] temp_WBval;  //dies in wb
        op_class_t op_class; //carried for verification
        mem_ctrl_t mem;      //dies in mem
        wb_ctrl_t wb;        //dies in wb
    } ex_mem_t;

    typedef struct packed {
        logic valid;
        logic [31:0] temp_WBval;
        op_class_t op_class;
        wb_ctrl_t wb;
        trace_t trace;
    } mem_wb_t;

endpackage