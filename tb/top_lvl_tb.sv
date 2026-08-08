`timescale 1ps/1ps
module top_lvl_tb;

    // Clock and reset signals
    logic clk;
    logic rst_n;
    logic [31:0] expected [0:31];
    string line;
    int dirty_file;
    int core_id, step_num, testnum, spike_reg, hex_addr, hex_instr, n;
    logic [31:0] reg_data;

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



    initial begin
        repeat (50) @(posedge clk);
        //opens the complex file from spike
        dirty_file = $fopen("commit.log","r");
        if(dirty_file == 0) begin
            $error("Error: Could not open commit.log");
            $finish;
        end
        $display("parsing log");
        //starts to iterate through the file getting all data
        while (!$feof(dirty_file)) begin
            if ($fgets(line, dirty_file)) begin
                if ($sscanf(line,"core %d: %d 0x%x (0x%x) x%d 0x%x", core_id, step_num, hex_addr, hex_instr, spike_reg, reg_data) == 6) begin    //looks at the string line from the log, then when finding matching fucntions, it asigns the it to its respective variable
                    if( hex_addr >= 32'h80000000) begin
                        expected[spike_reg] = reg_data;
                        $display("Parsed reg: 32'h%h | data: 32'h%h", spike_reg, reg_data);
                    end
                end
            end
        end

        if(dirty_file == 1) begin
            $fclose(dirty_file);
        end
        
        $display("Parsing complete.");

        testnum = 32;
        for(int i = 0; i < testnum; i++) begin
            if ($isunknown(expected[i])) continue;
            else if(dut.reg_file.regs[i] !== expected [i]) begin
                $error("FAIL x%0d: expected 0x%h, got 0x%h", i, expected[i], dut.reg_file.regs[i]);            
            end else begin
                $display("PASS x%0d: expected 0x%h, got 0x%h", i, expected[i], dut.reg_file.regs[i]);
            end
        end

        $finish;
    end
endmodule