CROSS   := riscv-none-elf-
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
CFLAGS  := -march=rv32im -mabi=ilp32 -nostdlib -nostartfiles
SIMDIR  := ../vivado/RISCV/RISCV.sim/sim_1/behav/xsim

all: sim

prog.elf: prog.S link.ld
	$(CC) $(CFLAGS) -T link.ld -o $@ $

prog.bin: prog.elf
	$(OBJCOPY) -O binary $< $@

program.hex: prog.bin bin2hex.py
	python3 bin2hex.py $< > $@

commit.log: prog.elf
	spike --isa=RV32IM --log-commits $< 2> $@

sim: program.hex commit.log
	cp program.hex commit.log $(SIMDIR)/

clean:
	rm -f prog.elf prog.bin program.hex commit.log

.PHONY: all sim clean