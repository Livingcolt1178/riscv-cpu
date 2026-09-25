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
# ================================== Paths ===================================


# ================================== Paths ===================================
set script_dir  [file dirname [file normalize [info script]]]
set repo        [file dirname $script_dir]                      ;# repo = /RISC-V
set constraints [file join $repo constraints.xdc]
set rtl_dir     [file join $repo rtl]
set hex         [file join $repo sw program.hex]
set out_dir     [file join $repo build fpga]
puts "paths set"
# ============================================================================


# =================================== Args ===================================
#todo
# ============================================================================


# ================================ Preflight =================================
#todo
# ============================================================================


# ================================= Sources ==================================
#this whole pkg shenangigans to make sure that the pkg is compiled first.
set pkg_file        [file join $rtl_dir $PKG]
set sv_files        [glob -nocomplain [file join $rtl_dir *.sv] [file join $rtl_dir * *.sv]]
set sv_files_no_pkg [lsearch -all -inline -not -exact $sv_files $pkg_file]
set design_sources  [concat [list $pkg_file] [lsort $sv_files_no_pkg]]
puts "[llength $design_sources] sources"
puts "sources set"
# ============================================================================


# ================================== Stage ===================================
file mkdir $out_dir
file copy -force $hex $out_dir      ;# sw/program.hex → build/fpga/
cd $out_dir
# ============================================================================


# ================================== Synth ===================================
read_verilog -sv $design_sources
read_xdc $constraints

synth_design -top $TOP -part $PART
write_checkpoint -force [file join $out_dir post_synth.dcp]
# ============================================================================


# =================================== Impl ===================================
#todo
# ============================================================================


# ================================ Bitstream =================================
#todo
# ============================================================================


# ================================= Summary ==================================
#todo
# ============================================================================
