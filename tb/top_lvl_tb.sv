`timescale 1ps/1ps
import riscv_pkg::*;
module top_lvl_tb;

    // Clock and reset signals
    logic clk;
    logic rst_n;
    logic [31:0] expected [0:31];
    string line;
    int dirty_file, testnum, i, j;
    int core_id, step_num;
    logic [31:0] pc, hex_instr, rd, rd_data, mem_addr, mem_data;

    typedef struct {
        int core_id, step_num;
        logic [31:0] pc, hex_instr, rd, rd_data, mem_addr, mem_data;
    } test_struct_t;


    test_struct_t spike_struct [0:4999];
    test_struct_t rtl_struct [0:4999];
    localparam int MAX_CYCLES = 5000;
    localparam int TOHOST = 32'h8000_13F0;  //do not forget to compare against link.ld

    // Instantiate the DUT (Device Under Test)
    top_lvl dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #20 rst_n = 1; // Release reset after 20 time units
    end

    //timeout failsafe
    initial begin
        repeat (MAX_CYCLES) @(posedge clk);
        $fatal(1, "FAIL: Pass Max Cycles");
    end

    task check(input string test_name, input logic [31:0] expected, input logic [31:0] got, input int cycle);
        if (got !== expected) begin
            $fatal(1, "[%d] FAIL %s: Expected 0x%h, Got 0x%h",
                   cycle, test_name, expected, got);
        end
    endtask 



    //spike absorption
    initial begin
        //opens the complex file from spike
        dirty_file = $fopen("commit.log","r");
        if(dirty_file == 0) begin
            $error("Error: Could not open commit.log");
            $finish;
        end
        $display("parsing log");
        //starts to iterate through the file getting all data
        i = 0;
        while (!$feof(dirty_file)) begin
            if ($fgets(line, dirty_file)) begin
                if ($sscanf(line,"core %d: %d 0x%x (0x%x)", core_id, step_num, pc, hex_instr) == 4) begin    //looks at the string line from the log, then when finding matching fucntions, it asigns the it to its respective variable
                    if( pc >= 32'h80000000) begin
                        spike_struct[i].core_id = core_id;
                        spike_struct[i].step_num = step_num;
                        spike_struct[i].pc = pc;
                        spike_struct[i].hex_instr = hex_instr;
                        if($sscanf(line,"core %d: %d 0x%x (0x%x) x%d 0x%x mem 0x%x",        core_id, step_num, pc, hex_instr, rd, rd_data, mem_addr) == 7)begin //load operation
                            spike_struct[i].rd = rd;
                            spike_struct[i].rd_data = rd_data;
                            spike_struct[i].mem_addr = mem_addr;

                        end else if ($sscanf(line,"core %d: %d 0x%x (0x%x) mem 0x%x 0x%x",  core_id, step_num, pc, hex_instr, mem_addr, mem_data) == 6) begin   //store operation
                            spike_struct[i].mem_addr = mem_addr;
                            spike_struct[i].mem_data = mem_data;


                        end else if ($sscanf(line,"core %d: %d 0x%x (0x%x) x%d 0x%x",       core_id, step_num, pc, hex_instr, rd, rd_data) == 6) begin          //any reg operation
                            spike_struct[i].rd = rd;
                            spike_struct[i].rd_data = rd_data;
                        end
                        i++;
                    end
                end else begin
                    $fatal(1, "[line: %d] unparseable line: %s ", i, line);     //nothing not matching these formats should pass
                end
            end
        end
        if(dirty_file != 0) begin
            $fclose(dirty_file);
        end
        
        $display("Parsing complete.");
    end

    //rtl absorbption
    initial begin
        j = 0;
         
        forever begin
            @(posedge clk);
            if(dut.mem_wb_q.valid) begin //to allow the pipeline to fill and start retiring before we start the checking
                

                rtl_struct[j].pc = dut.mem_wb_q.pc;
                rtl_struct[j].hex_instr = dut.mem_wb_q.trace.inst;
                if(dut.mem_wb_q.wb.we_reg != 0 && dut.mem_wb_q.wb.rd != 0) begin
                    rtl_struct[j].rd = dut.mem_wb_q.wb.rd;
                    rtl_struct[j].rd_data = dut.wb_WBval;
                end
                if(dut.mem_wb_q.op_class == STORE || dut.mem_wb_q.op_class == LOAD) begin
                    rtl_struct[j].mem_addr = dut.mem_wb_q.alu_out;
                end
                if(dut.mem_wb_q.op_class == STORE) begin
                    case(dut.mem_wb_q.trace.fct3) //this is due to idealized memory and not having done lane select yet
                        3'b000: rtl_struct[j].mem_data = dut.mem_wb_q.trace.mem_wdata[7:0];
                        3'b001: rtl_struct[j].mem_data = dut.mem_wb_q.trace.mem_wdata[15:0];
                        3'b010: rtl_struct[j].mem_data = dut.mem_wb_q.trace.mem_wdata;
                        default:rtl_struct[j].mem_data = dut.mem_wb_q.trace.mem_wdata;
                    endcase
                end 

                check("pc",         spike_struct[j].pc,         rtl_struct[j].pc,       j);
                check("hex_instr",  spike_struct[j].hex_instr,  rtl_struct[j].hex_instr,j);
                check("rd",         spike_struct[j].rd,         rtl_struct[j].rd,       j);
                check("rd_data",    spike_struct[j].rd_data,    rtl_struct[j].rd_data,  j);
                check("mem_addr",   spike_struct[j].mem_addr,   rtl_struct[j].mem_addr, j);
                check("mem_data",   spike_struct[j].mem_data,   rtl_struct[j].mem_data, j);

                if(dut.mem_wb_q.valid && dut.mem_wb_q.op_class == STORE && dut.mem_wb_q.alu_out == TOHOST) break;
                j++;
                if (j >= i) $fatal(1, "core still running at cycle %0d; Spike retired only %0d instructions", j, i);
            end
        end
        $display("PASSED ALL TESTS, rtl tests: %d, spike tests: %d" ,j, i);
        $finish;
    end
endmodule