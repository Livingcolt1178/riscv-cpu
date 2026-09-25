#first we tell the script where it is
set script_dir  [file dirname [file normalize [info script]]];
set repo        [file dirname $script_dir]; # repo = /RISC-V
#next we tell the script where the sources are  
set constraints [file join $repo constraints.xdc];
set rtl_dir     [file join $repo rtl];
set tb          [file join $repo tb top_lvl_tb.sv];
set hex         [file join $repo sw program.hex];
set out_dir     [file join $repo build tcl];
set top         FPGA_top;
set part        xc7s15ftgb196-1;
set pkg         riscv_pkg.sv;
set pkg_file    [file join $rtl_dir $pkg];
set sv_files    [glob -nocomplain [file join $rtl_dir *.sv] [file join $rtl_dir * *.sv]];
set sv_files_no_pkg [lsearch -all -inline -not -exact $sv_files $pkg_file];
set design_sources [concat [list $pkg_file] [lsort $sv_files_no_pkg]];
if {![file exists $out_dir]} {
    file mkdir $out_dir
    puts "Created directory: $out_dir"
}
file copy -force $hex $out_dir      ;# sw/program.hex → build/fpga/
cd $out_dir;
# first we read all the data
read_verilog -sv $design_sources
read_xdc $constraints;

synth_design -top $top -part $part
write_checkpoint -force $out_dir

