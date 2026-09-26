# ============================================================================
# build.tcl — RTL to routed bitstream.
#
#   vivado -mode batch -notrace -source scripts/build.tcl \
#          -log build/fpga/vivado.log -journal build/fpga/vivado.jou \
#          -tclargs [synth|impl|bit]          (default: bit)
#
#   From WSL, call vivado.bat through cmd.exe with wslpath -w paths,
#   the same way run_tests.sh calls xsim.
#
# Outputs go to build/fpga/: checkpoints, reports, bitstream, summary.txt.
# Nothing is written outside that directory.
#
# Non-project mode on purpose. A Vivado project copies sources into its own
# run directories, and a stale copy silently served old data on 2026-08-08.
# Reading straight from rtl/ leaves nothing to go stale, and every build is
# reproducible from a clean checkout.
#
# program.hex is baked into instruction memory at synthesis. $readmemh
# resolves INIT_FILE against Vivado's working directory, so the script
# copies sw/program.hex into build/fpga/ and runs from there. Build the
# program first: make -C sw SRC=<test>.S program.hex
#
# Exit codes (same convention as run_tests.sh):
#   0  all requested stages done, all guards passed
#   1  build ran and failed (tool error, guard, timing)
#   2  bad usage or missing input; the flow never started

# Header comment drafted with Claude (claude-opus-5-5), 2026-09-25. Rest is Nicholas'
# ============================================================================

# ================================== Config ==================================
set TOP         FPGA_top
set PART        xc7s15ftgb196-1
set PKG         riscv_pkg.sv
puts "config set"
# ============================================================================


# ================================== Paths ===================================
set script_dir  [file dirname [file normalize [info script]]]
set repo        [file dirname $script_dir]                      ;# repo = /RISC-V
set constraints [file join $repo constraints.xdc]
set rtl_dir     [file join $repo rtl]
set hex         [file join $repo sw program.hex] ;#maybe find a way to pull it directly from the pkg so that it doesn't drift?
set out_dir     [file join $repo build fpga]
set pkg_file        [file join $rtl_dir $PKG]
puts "paths set"
# ============================================================================


# =================================== Args ===================================
if {$argc == 0} {
    set stage "bit"
} else {
    set stage [lindex $argv 0]
}
if {$stage ni {bit synth impl}} {
    puts "stage: $stage, does not exist"
    exit 2
}
# ============================================================================


# ================================= Sources ==================================
#this whole pkg shenangigans to make sure that the pkg is compiled first.

set sv_files        [glob -nocomplain [file join $rtl_dir *.sv] [file join $rtl_dir * *.sv]]
set sv_files_no_pkg [lsearch -all -inline -not -exact $sv_files $pkg_file]
set design_sources  [concat [list $pkg_file] [lsort $sv_files_no_pkg]]
puts "[llength $design_sources] sources"
puts "sources set"
# ============================================================================


# ================================ Preflight =================================
foreach f [list $hex $pkg_file $constraints] {
    if {![file isfile $f]} {
        puts "ERROR: missing $f"; exit 2
    }
}
if {[llength $sv_files] == 0} {
    puts "$rtl_dir is empty"
    exit 2
}
puts "preflight passed"
# ============================================================================


# ================================== Stage ===================================
file mkdir $out_dir
file copy -force $hex $out_dir      ;# sw/program.hex → build/fpga/
cd $out_dir
# ============================================================================


# ================================== Synth ===================================
#this is to make sure that the hex program actually loads properly and fails if it doesn't
set_msg_config -id {Synth 8-4445} -new_severity ERROR

read_verilog -sv $design_sources
read_xdc $constraints
synth_design -top $TOP -part $PART
write_checkpoint -force [file join $out_dir post_synth.dcp]
report_utilization -file $out_dir/post_synth_utilization_report.rpt
report_timing -file $out_dir/post_synth_timing_report.rpt
set n [llength [get_cells -hier -filter {REF_NAME == RAMB18E1}]]
# if the design changes, this might have to be changed, but as it stands the correct
# build has 2 BRAMS, so less than that it means the build didn't load properly.
if {$n < 2} { 
    puts "BUILD: FAIL - G2 - expected 2 RAMB18E1, got $n"
    exit 1
}
if {$stage eq "synth"}  {
    puts "BUILD: PASS (synth)"
    exit 0
}
# ============================================================================


# =================================== Impl ===================================
opt_design
place_design
route_design
write_checkpoint -force [file join $out_dir post_impl.dcp]
report_utilization -file $out_dir/post_impl_utilization_report.rpt
report_timing_summary -max_paths 10 -file $out_dir/post_impl_timing_report.rpt
set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
set whs [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -hold]]
if {$wns < 0} {
    puts "BUILD: FAIL - G3 - setup WNS $wns ns"
    exit 1
}
if {$whs < 0} {
    puts "BUILD: FAIL - G4 - hold WHS $whs ns"
    exit 1
}
puts "WNS $wns ns   WHS $whs ns"
if {$stage eq "impl"}  {
    puts "BUILD: PASS (impl)"
    exit 0
}
# ============================================================================


# ================================ Bitstream =================================

write_bitstream -force $out_dir/riscv.bit
puts "BUILD: PASS (bit)"
exit 0
# ============================================================================


# ================================= Summary ==================================
proc write_summary {result} {
    #TODO
}
# ============================================================================
