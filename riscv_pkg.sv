package riscv_pkg;

    typedef enum logic [2:0] {
        R,
        I,
        S,
        B,
        U,
        J
    } format_t;

    typedef enum logic [4:0] {
            ALU_ADD,
            ALU_SUB,
            ALU_SLL,
            ALU_SLT,
            ALU_SLTU, 
            ALU_XOR,   
            ALU_SRL,     
            ALU_SRA,
            ALU_OR,
            ALU_AND,
            ALU_BEQ,
            ALU_BNE,
            ALU_BLT,
            ALU_BGE, 
            ALU_BLTU,
            ALU_BGEU,

            HOLD
    } ALU_fct3_T;


endpackage