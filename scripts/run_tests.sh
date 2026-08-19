#!/usr/bin/env bash
# ============================================================================
# run_tests.sh — the regression. One command, one verdict.
#
#   ./scripts/run_tests.sh
#
# For each test program: rebuild from source in WSL (gcc + Spike), then
# compile and run the RTL with Vivado's command-line simulator on the Windows
# side. Prints one line per test and exits nonzero if any failed.
#
# No Vivado project (.xpr) is involved. That is deliberate — the project's
# sim_1 fileset copies files at elaboration, which silently served a stale
# commit.log on 2026-08-08. Standalone xvlog/xelab/xsim reads straight from
# the working directory, so there is nothing to go stale.
# ============================================================================
set -uo pipefail

# ---- config ---------------------------------------------------------------
# Directory containing xvlog.bat / xelab.bat / xsim.bat. Override per-run:
#   VIVADO_BIN=/mnt/c/Xilinx/Vivado/2023.2/bin ./scripts/run_tests.sh
VIVADO_BIN="${VIVADO_BIN:-/mnt/c/AMDDesignTools/2025.2/Vivado/bin}"

# Test programs, in order. Add new .S files here.
TESTS=(prog.S prog_nop.S coverage_nop.S coverage.S loaduse.S loads.S flushshadow.S)

TOP=top_lvl_tb          # testbench module name
SNAPSHOT=tb_sim         # xelab output name

# ---- paths ----------------------------------------------------------------
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SW="$REPO/sw"
WORK="$REPO/build"

# ---- preflight ------------------------------------------------------------
# Fail loudly here rather than three steps in with a confusing error.
for tool in xvlog xelab xsim; do
    if [[ ! -f "$VIVADO_BIN/$tool.bat" ]]; then
        echo "ERROR: $VIVADO_BIN/$tool.bat not found."
        echo "       Set VIVADO_BIN to your Vivado bin directory, e.g."
        echo "       VIVADO_BIN=/mnt/c/Xilinx/Vivado/2023.2/bin $0"
        exit 2
    fi
done
command -v spike   >/dev/null || { echo "ERROR: spike not on PATH";   exit 2; }
command -v riscv-none-elf-gcc >/dev/null || { echo "ERROR: riscv-none-elf-gcc not on PATH"; exit 2; }

# WSL can't execute .bat directly (it's not a PE binary), so everything goes
# through cmd.exe, which needs Windows-style paths.
XVLOG="$(wslpath -w "$VIVADO_BIN/xvlog.bat")"
XELAB="$(wslpath -w "$VIVADO_BIN/xelab.bat")"
XSIM="$(wslpath  -w "$VIVADO_BIN/xsim.bat")"

# Source list. riscv_pkg must compile first — it defines the types everything
# else imports.
SOURCES=("$REPO/rtl/riscv_pkg.sv")
while IFS= read -r f; do
    [[ "$f" == *riscv_pkg.sv ]] && continue
    SOURCES+=("$f")
done < <(find "$REPO/rtl" -name '*.sv' | sort)
SOURCES+=("$REPO/tb/$TOP.sv")

WIN_SOURCES=()
for f in "${SOURCES[@]}"; do WIN_SOURCES+=("$(wslpath -w "$f")"); done

mkdir -p "$WORK"
cd "$WORK"

# ---- run ------------------------------------------------------------------
declare -a RESULTS=()
FAILURES=0

for test in "${TESTS[@]}"; do
    name="${test%.S}"
    log="$WORK/$name.log"
    printf '\n=== %s ===\n' "$test"

    # `make clean` is not optional. Every SRC builds the same target name
    # (prog.elf), so make would happily reuse an ELF built from a different
    # .S file and the run would silently test the wrong program.
    make -C "$SW" clean >/dev/null 2>&1

    if ! make -C "$SW" SRC="$test" program.hex commit.log > "$log" 2>&1; then
        echo "  build FAILED — see $log"
        RESULTS+=("FAIL  $test  (build)")
        FAILURES=$((FAILURES + 1))
        continue
    fi

    # xsim resolves $readmemh and $fopen against its working directory.
    cp "$SW/program.hex" "$SW/commit.log" "$WORK/"

    # Delete the snapshot BEFORE elaborating. A failed xvlog/xelab leaves the
    # previous run's snapshot in place, and `xsim tb_sim -R` will happily run
    # it and print PASSED ALL TESTS for code that no longer compiles. That is
    # not hypothetical: on 2026-08-12 a duplicate enum member broke
    # riscv_pkg.sv, the stale library elaborated, and the suite reported
    # PASS (2/2) on a design containing an uninstantiated forwarding unit.
    rm -rf "$WORK/xsim.dir"

    # Each tool's exit code is checked. `set -e` would not help — these are
    # bare cmd.exe calls whose status was previously discarded, so a tool
    # that died produced no PASSED ALL TESTS, the verdict was correctly FAIL,
    # and the *reason* was buried in the log. Naming the failing stage here
    # is the difference between a one-line answer and a bisect.
    if ! cmd.exe /c "$XVLOG" -sv "${WIN_SOURCES[@]}" >> "$log" 2>&1; then
        echo "  FAIL — xvlog (compile)"
        grep -E "^ERROR" "$log" | head -5 | sed 's/^/    /'
        RESULTS+=("FAIL  $test  (xvlog)")
        FAILURES=$((FAILURES + 1))
        continue
    fi

    # -timescale supplies a default for modules that declare none. Only the
    # testbench has a `timescale directive; the Vivado GUI project was
    # silently providing this and standalone xelab is not.
    if ! cmd.exe /c "$XELAB" -debug typical -timescale 1ps/1ps \
                             "$TOP" -s "$SNAPSHOT" >> "$log" 2>&1; then
        echo "  FAIL — xelab (elaborate)"
        grep -E "^ERROR" "$log" | head -5 | sed 's/^/    /'
        RESULTS+=("FAIL  $test  (xelab)")
        FAILURES=$((FAILURES + 1))
        continue
    fi

    # Belt and braces: a zero exit status from a .bat wrapper is not proof the
    # snapshot exists. Check the artifact itself before trusting the run.
    if [[ ! -d "$WORK/xsim.dir/$SNAPSHOT" ]]; then
        echo "  FAIL — xelab reported success but produced no snapshot"
        RESULTS+=("FAIL  $test  (no snapshot)")
        FAILURES=$((FAILURES + 1))
        continue
    fi

    if ! cmd.exe /c "$XSIM" "$SNAPSHOT" -R >> "$log" 2>&1; then
        echo "  FAIL — xsim (simulate)"
        grep -E "^ERROR|Fatal" "$log" | head -5 | sed 's/^/    /'
        RESULTS+=("FAIL  $test  (xsim)")
        FAILURES=$((FAILURES + 1))
        continue
    fi

    # Verdict requires POSITIVE evidence of success, not merely the absence
    # of the word FAIL. A run that dies before the checker starts produces
    # no failures either — that exact ambiguity is what an empty commit.log
    # looked like on 2026-08-08.
    if grep -q "PASSED ALL TESTS" "$log" && ! grep -qE "FAIL|Fatal" "$log"; then
        counts="$(grep -o 'rtl tests:.*' "$log" | tail -1)"
        echo "  PASS  ${counts:-}"
        RESULTS+=("PASS  $test  ${counts:-}")
    else
        echo "  FAIL — see $log"
        # Include ERROR so a build/elaboration failure shows its cause here
        # instead of only in the log.
        grep -E "FAIL|Fatal|ERROR" "$log" | head -5 | sed 's/^/    /'
        RESULTS+=("FAIL  $test")
        FAILURES=$((FAILURES + 1))
    fi
done

# ---- verdict --------------------------------------------------------------
echo
echo "=============================================================="
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "=============================================================="
if (( FAILURES == 0 )); then
    echo "REGRESSION: PASS (${#TESTS[@]}/${#TESTS[@]})"
    exit 0
else
    echo "REGRESSION: FAIL ($FAILURES/${#TESTS[@]} failed)"
    exit 1
fi
