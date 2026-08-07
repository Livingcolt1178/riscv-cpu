OUTPUT_ARCH("riscv")
ENTRY(_start)
SECTIONS {
  . = 0x80000000;
  .text : { *(.text) }
  .tohost 0x800003FC : { *(.tohost) }
}