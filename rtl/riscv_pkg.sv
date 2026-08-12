package riscv_pkg;

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
            FENCE
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
    } wb_ctrl_t;

    typedef struct packed {
        logic [31:0] inst, mem_wdata;
        logic [2:0] fct3;
    } trace_t;

    typedef struct packed {
        logic valid;
        logic [31:0] pc, inst;
    } if_id_t;
    
    typedef struct packed {
        logic valid;
        logic [31:0] pc, inst; //inst because we need for verification
        logic [31:0] imm, S1val, S2val;
        logic [4:0] rs1, rs2;
        op_class_t op_class;
        ex_ctrl_t ex;
        mem_ctrl_t mem;
        wb_ctrl_t wb;
    } id_ex_t;

    typedef struct packed {
        logic valid;
        logic [31:0] pc, inst; //inst because we need for verification
        logic [31:0] ta, alu_out, S2val, WBval;
        op_class_t op_class;
        mem_ctrl_t mem;
        wb_ctrl_t wb;
    } ex_mem_t;

    typedef struct packed {
        logic valid;
        logic [31:0] pc; 
        logic [31:0] ta, alu_out, mem_out, WBval;
        op_class_t op_class;
        wb_ctrl_t wb;
        trace_t trace;
    } mem_wb_t;

endpackage