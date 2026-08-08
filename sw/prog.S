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
    li t0, 0x800003F0
    li t1, 1
    sw t1, 0(t0)
loop:
    jal  x0, loop
