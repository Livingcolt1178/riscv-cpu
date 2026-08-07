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
    } ALU_fct3_t;

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


endpackage