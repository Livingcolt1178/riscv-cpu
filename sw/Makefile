AS = riscv-none-elf-as
LD = riscv-none-elf-ld
OBJCOPY = riscv-none-elf-objcopy

program.hex: prog.elf
	$(OBJCOPY) -O binary prog.elf prog.bin
	python3 bin2hex.py prog.bin > program.hex

prog.elf: prog.o link.ld
	$(LD) -T link.ld prog.o -o prog.elf

prog.o: prog.S
	$(AS) -march=rv32im -mabi=ilp32 prog.S -o prog.o

clean:
	rm -f *.o *.elf *.bin