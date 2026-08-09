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
	$(OBJCOPY) -O binary $< $@

program.hex: prog.bin bin2hex.py
	python3 bin2hex.py $< > $@

commit.log: prog.elf
	spike --isa=RV32IM --log-commits $< 2> $@

# The ELF is the arbiter, not link.ld and the .S file that are supposed to agree.
hostcheck: prog.elf
	@$(NM) $< | grep host

sim: program.hex commit.log
	@test -d $(SIMDIR) || { echo "SIMDIR missing: $(SIMDIR) — run scripts/build_project.tcl first"; exit 1; }
	cp program.hex commit.log $(SIMDIR)/

clean:
	rm -f prog.elf prog.bin prog.o program.hex commit.log

.PHONY: all sim clean hostcheck
