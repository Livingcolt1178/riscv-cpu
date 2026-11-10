#clk, name: CLK, port: H4
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk_100_i]
set_property PACKAGE_PIN H4 [get_ports clk_100_i]         
set_property IOSTANDARD LVCMOS33 [get_ports clk_100_i]

create_generated_clock -name clk_in -source [get_ports clk_100_i] -divide_by 2 [get_pins bufg_core/O]

#rst, name: FPGA_RST, port: D14
set_property PACKAGE_PIN D14 [get_ports rst_button_ni]          
set_property IOSTANDARD LVCMOS33 [get_ports rst_button_ni]
set_false_path -from [get_ports rst_button_ni]

#Led green, Name: FPGA_LED1, port: J1
set_property PACKAGE_PIN J1 [get_ports led_green_o]       
set_property IOSTANDARD LVCMOS33 [get_ports led_green_o]
set_false_path -to [get_ports led_green_o]

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]