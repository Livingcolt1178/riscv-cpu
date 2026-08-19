#clk, name: CLK, port: H4
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
set_property PACKAGE_PIN H4 [get_ports clk]         
set_property IOSTANDARD LVCMOS33 [get_ports clk]

#rst, name: FPGA_RST, port: D14
set_property PACKAGE_PIN D14 [get_ports rst_n]          
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

#Led green, Name: FPGA_LED1, port: J1
set_property PACKAGE_PIN J1 [get_ports led_green]       
set_property IOSTANDARD LVCMOS33 [get_ports led_green]