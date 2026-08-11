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

commit.log: prog.elf
	timeout -k 5 120 spike --isa=RV32IM --log-commits $< < /dev/null 2> /tmp/commit.log || \
	  { echo "ERROR: spike did not terminate"; exit 1; }
	cp /tmp/commit.log $@

# The ELF is the arbiter, not link.ld and the .S file that are supposed to agree.
hostcheck: prog.elf
	@$(NM) $< | grep host

sim: program.hex commit.log
	@test -d $(SIMDIR) || { echo "SIMDIR missing: $(SIMDIR) — run scripts/build_project.tcl first"; exit 1; }
	cp program.hex commit.log $(SIMDIR)/

clean:
	rm -f prog.elf prog.bin prog.o program.hex commit.log
	rm -f sw/*_nop.S

.PHONY: all sim clean hostcheck
