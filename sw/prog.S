.section .tohost, "aw", @progbits
.align 3
.global tohost
tohost:   .dword 0
.align 3
.global fromhost
fromhost: .dword 0

.section .text
.global _start
_start:
    addi x1, x0, 5
    addi x2, x0, 7
    addi x3, x1, 10
    auipc x7, 0
    jal   x8, next
next:
    # --- peripheral store: light led_green -------------------------------
    # Any address in [0x1000, 0x8000_0000) asserts we_periph (MMIO_unit.sv).
    # 0x20000000 dodges Spike's platform devices (rstvec 0x1000, CLINT,
    # PLIC, UART 0x10000000). Must stay in sync with SPIKE_MEM in the Makefile.
    # LED_IO latches high on a nonzero store, low on a zero store.
    .equ LED_ADDR, 0x20000000
    lui  t2, %hi(LED_ADDR)
    addi t2, t2, %lo(LED_ADDR)
    addi t3, x0, 1
    sw   t3, 0(t2)
    # ---------------------------------------------------------------------
    lui  t0, %hi(tohost)
    addi t0, t0, %lo(tohost)
    addi t1, x0, 1
    sw  t1, 0(t0)
loop:
    jal x0, loop