#clk, name: SYSCLK, port: H4
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
set_property PACKAGE_PIN H4 [get_ports clk]         
set_property IOSTANDARD LVCMOS33 [get_ports clk]

#rst, name: FPGA_RST, port: D14
set_property PACKAGE_PIN D14 [get_ports rst_n]          
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]