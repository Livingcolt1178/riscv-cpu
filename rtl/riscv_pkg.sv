`timescale 1ns/1ps
package riscv_pkg;

    parameter string INIT_FILE = "program.hex";
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
            AluAdd,
            AluSub,
            AluSll,
            AluSlt,
            AluSltu,
            AluXor,
            AluSrl,
            AluSra,
            AluOr,
            AluAnd
    } alu_fct3_t;

    typedef enum logic [3:0] {
            Nop,

            Alu,
            Load,
            Store,
            Branch,
            Jump,
            JumpR,
            Lui,
            Auipc,
            Fence   //not yet implemented
    } op_class_t;

    typedef enum logic [1:0] {
        FwdNone,
        FwdEx,
        FwdMem
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
        //need this because the wbvalue must get passed back in due to reg file straddleing id and wb.
        logic we_reg;
        logic [4:0] rd;
        logic [1:0] lane;
        logic [2:0] fct3;
    } wb_ctrl_t;

    typedef struct packed {
        logic [31:0] inst, alu_result, mem_wdata, pc;
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
        logic [31:0] imm, rs1_data; //dies in ex
        logic [31:0] rs2_data;      //dies in mem
        logic [4:0] rs1_addr, rs2_addr;    //dies in ex, used for forwarding
        op_class_t op_class;     //dies in mem
        ex_ctrl_t ex;            //dies in ex
        mem_ctrl_t mem;          //dies in mem
        wb_ctrl_t wb;            //dies in wb
    } id_ex_t;

    typedef struct packed {
        logic valid;
        logic [31:0] pc, inst, alu_result;              //carried for verification
        logic [31:0] rs2_data;  //dies in mem
        logic [31:0] temp_wb_data;  //dies in wb
        op_class_t op_class; //carried for verification
        mem_ctrl_t mem;      //dies in mem
        wb_ctrl_t wb;        //dies in wb
    } ex_mem_t;

    typedef struct packed {
        logic valid;
        logic [31:0] temp_wb_data;
        op_class_t op_class;
        wb_ctrl_t wb;
        trace_t trace;
    } mem_wb_t;

endpackage
