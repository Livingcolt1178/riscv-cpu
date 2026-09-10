CROSS   := riscv-none-elf-
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
NM      := $(CROSS)nm
CFLAGS  := -march=rv32im -mabi=ilp32 -nostdlib -nostartfiles
SIMDIR  := ../vivado/RISCV/RISCV.sim/sim_1/behav/xsim

# Which program to build. Override on the command line:
#   make SRC=coverage.S sim
SRC     ?= prog.S

all: sim

prog.elf: $(SRC) link.ld
	$(CC) $(CFLAGS) -T link.ld -o $@ $<

prog.bin: prog.elf
	$(OBJCOPY) -O binary -j .text $< $@

coverage_nop.S: coverage.S pad.py
	python3 pad.py $< > $@

%_nop.S: %.S pad.py
	python3 pad.py $< > $@

.PRECIOUS: %_nop.S

program.hex: prog.bin bin2hex.py
	python3 bin2hex.py $< > $@

# Spike's default map is DRAM only, at 0x80000000. The peripheral store lands in
# [0x1000, 0x8000_0000) (MMIO_unit.sv), which is unmapped there -- Spike takes a
# store access fault and the trap line it logs matches none of the testbench's
# $sscanf formats, so it surfaces as "unparseable line", not as a memory error.
#
# The window has to dodge Spike's own platform devices. Occupied by default:
#   0x00001000  DEFAULT_RSTVEC, boot ROM + DTS  (mapping RAM here => never reaches _start)
#   0x02000000  CLINT
#   0x0c000000  PLIC
#   0x10000000  NS16550 UART, 0x100 long       ("devices at ... overlap")
#   0x80000000  DRAM
# 0x20000000 is clear. Must stay in sync with LED_ADDR in prog.S.
SPIKE_MEM := -m0x20000000:0x1000,0x80000000:0x10000000

commit.log: prog.elf
	timeout -k 5 120 spike --isa=RV32IM $(SPIKE_MEM) --log-commits $< < /dev/null 2> /tmp/commit.log || \
	  { echo "ERROR: spike did not terminate"; \
	    echo "--- last 15 lines of the commit log ---"; \
	    tail -15 /tmp/commit.log; \
	    exit 1; }
	cp /tmp/commit.log $@

# The ELF is the arbiter, not link.ld and the .S file that are supposed to agree.
hostcheck: prog.elf
	@$(NM) $< | grep host

sim: program.hex commit.log
	@test -d $(SIMDIR) || { echo "SIMDIR missing: $(SIMDIR) — run scripts/build_project.tcl first"; exit 1; }
	cp program.hex commit.log $(SIMDIR)/


# Run this immediately before generating a bitstream, and do not run the
# regression in between.
BITSTREAM_SRC ?= hwtest.S

bitstream-hex:
	$(MAKE) clean
	$(MAKE) SRC=$(BITSTREAM_SRC) program.hex
	cp program.hex ../build/program.hex
	@echo ""
	@echo "build/program.hex now holds $(BITSTREAM_SRC)."
	@echo "Synthesise now. Running scripts/run_tests.sh will overwrite it again."

clean:
	rm -f prog.elf prog.bin prog.o program.hex commit.log
	rm -f sw/*_nop.S

.PHONY: all sim clean hostcheck bitstream-hex
