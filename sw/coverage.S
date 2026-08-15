# ============================================================================
# coverage.S — RV32I stage 5 coverage program
#
# Checked per-cycle against Spike by the lockstep testbench. Nothing here
# encodes an expected value; Spike is the oracle. This file only has to
# *exercise* instructions and reach the tohost store on every path.
#
# Constraints this program is written under:
#   1. The core is Harvard with no $readmemh on the data array, so it has NO
#      initialized data. Every load must be preceded by a store to the same
#      address. A .data section would be visible to Spike and invisible to
#      the core.
#   2. data_cache ignores misalignment (documented V1 decision), so halfword
#      accesses stay on 2-byte boundaries and word accesses on 4-byte.
#   3. Sub-word stores leave the rest of the word X in the core and 0 in
#      Spike. Never read back a byte/half that was not explicitly written.
#   4. Every path must reach the tohost store. It is the program's exit().
#
# Data scratch: 0x80000300..0x8000030B. Clear of .text below and of
# tohost/fromhost at 0x800003F0.
# ============================================================================

    .section .tohost, "aw", @progbits
    .align 3
    .global tohost
tohost:     .dword 0
    .align 3
    .global fromhost
fromhost:   .dword 0

    .section .text
    .global _start
_start:

# ---------------------------------------------------------------------------
# operands
# ---------------------------------------------------------------------------
    addi  x5,  x0, 100            # 0x64
    addi  x6,  x0, 37             # 0x25
    addi  x7,  x0, -5             # sign-extended negative immediate
    addi  x8,  x0, 1

# ---------------------------------------------------------------------------
# R-type ALU — all ten
# ---------------------------------------------------------------------------
    add   x10, x5, x6             # 137
    sub   x11, x5, x6             # 63
    sub   x12, x6, x5             # -63, negative result
    sll   x13, x5, x8             # 200
    slt   x14, x7, x6             # 1   signed: -5 < 37
    slt   x15, x6, x7             # 0
    sltu  x16, x7, x6             # 0   unsigned: -5 is 0xFFFFFFFB
    sltu  x17, x6, x7             # 1
    xor   x18, x5, x6
    srl   x19, x7, x8             # logical shift of a negative
    sra   x20, x7, x8             # arithmetic: -3
    or    x21, x5, x6
    and   x22, x5, x6

# ---------------------------------------------------------------------------
# I-type ALU — all nine
# ---------------------------------------------------------------------------
    addi  x23, x5, -50            # 50
    slti  x24, x7, 0              # 1
    slti  x25, x5, 0              # 0
    sltiu x26, x7, 1              # 0
    sltiu x27, x0, 1              # 1
    xori  x28, x5, -1             # ones complement
    ori   x29, x5, 0x0F
    andi  x30, x5, 0x0F
    slli  x31, x5, 3
    srli  x9,  x7, 4              # logical
    srai  x4,  x7, 4              # arithmetic: -1

# ---------------------------------------------------------------------------
# LUI / AUIPC
# ---------------------------------------------------------------------------
    lui   x3,  0xABCDE            # 0xABCDE000
    auipc x10, 0                  # PC of this instruction
    auipc x11, 1                  # PC + 0x1000

# ---------------------------------------------------------------------------
# JAL / JALR
#   jal writes rd and jumps forward; the skipped instruction is a control-flow
#   check — if the jump does not happen, the PC comparison fails immediately.
# ---------------------------------------------------------------------------
    jal   x1, jal_tgt
    addi  x12, x0, 0x7AD          # must not execute
jal_tgt:
    jal   x1, subr1               # call, x1 = return address
ret1:
    jal   x1, subr2               # call, returns via jalr with rd != 0
ret2:

# ---------------------------------------------------------------------------
# memory — store then load, every width
# ---------------------------------------------------------------------------
    lui   x2,  0x80000
    addi  x2,  x2, 0x300          # x2 = 0x80000300, scratch base

    lui   x5,  0x12345
    addi  x5,  x5, 0x678          # x5 = 0x12345678

    sw    x5,  0(x2)
    lw    x6,  0(x2)              # 0x12345678

    addi  x7,  x0, -1             # 0xFFFFFFFF
    sb    x7,  4(x2)              # byte lane 0
    lb    x8,  4(x2)              # -1, sign extended
    lbu   x9,  4(x2)              # 255, zero extended

    addi  x13, x0, 0x7A
    sb    x13, 5(x2)              # byte lane 1 — exercises the lane logic
    lb    x14, 5(x2)              # 0x7A
    lbu   x15, 5(x2)              # 0x7A

    addi  x16, x0, -2             # 0xFFFFFFFE
    sh    x16, 8(x2)              # halfword lane 0
    lh    x17, 8(x2)              # -2, sign extended
    lhu   x18, 8(x2)              # 65534, zero extended

    lui   x19, 0x0000C
    addi  x19, x19, 0x0D0
    sh    x19, 10(x2)             # halfword lane 2
    lh    x20, 10(x2)
    lhu   x21, 10(x2)

# ---------------------------------------------------------------------------
# branches — every condition, taken
#   Each skipped addi is the observable: a branch that fails to take executes
#   it, and the PC comparison fires on that cycle.
# ---------------------------------------------------------------------------
    addi  x5,  x0, 10
    addi  x6,  x0, 20
    addi  x7,  x0, -10

    beq   x5, x5, T1
    addi  x22, x0, 1
T1: bne   x5, x6, T2
    addi  x22, x0, 2
T2: blt   x5, x6, T3
    addi  x22, x0, 3
T3: bge   x6, x5, T4
    addi  x22, x0, 4
T4: bltu  x5, x6, T5
    addi  x22, x0, 5
T5: bgeu  x6, x5, T6
    addi  x22, x0, 6
T6:

# ---------------------------------------------------------------------------
# branches — every condition, not taken
# ---------------------------------------------------------------------------
    beq   x5, x6, N1
    addi  x23, x0, 1              # executes
N1: bne   x5, x5, N2
    addi  x23, x0, 2
N2: blt   x6, x5, N3
    addi  x23, x0, 3
N3: bge   x5, x6, N4
    addi  x23, x0, 4
N4: bltu  x6, x5, N5
    addi  x23, x0, 5
N5: bgeu  x5, x6, N6
    addi  x23, x0, 6
N6:

# ---------------------------------------------------------------------------
# signed vs unsigned discriminator
#   Same two registers, opposite outcomes. If the core treats BLT and BLTU
#   identically this is the pair that catches it — the twelve above would all
#   still pass.
# ---------------------------------------------------------------------------
    blt   x7, x5, S1              # taken:     -10 <  10  signed
    addi  x24, x0, 1
S1: bltu  x7, x5, S2              # not taken: 0xFFFFFFF6 > 10 unsigned
    addi  x24, x0, 2
S2: bge   x7, x5, S3              # not taken
    addi  x25, x0, 1
S3: bgeu  x7, x5, S4              # taken
    addi  x25, x0, 2
S4:
# ---------------------------------------------------------------------------
# equality boundary — the only input where >= and > differ
#   bge/bgeu are the complement of a *strict* SLT/SLTU, so rs1 == rs2 must
#   branch. A comparator that is accidentally non-strict inverts every line
#   in this block and passes every branch test above it.
# ---------------------------------------------------------------------------
    bge   x5, x5, E1              # taken:     10 >= 10   signed
    addi  x28, x0, 1
E1: bgeu  x5, x5, E2              # taken:     10 >= 10   unsigned
    addi  x28, x0, 2
E2: bge   x7, x7, E3              # taken:    -10 >= -10  sign bit set
    addi  x28, x0, 3
E3: bgeu  x7, x7, E4              # taken:     same operands, unsigned path
    addi  x28, x0, 4
E4: blt   x5, x5, E5              # not taken: strictness
    addi  x29, x0, 1
E5: bltu  x7, x7, E6              # not taken: strictness, sign bit set
    addi  x29, x0, 2
E6:

# ---------------------------------------------------------------------------
# backward branch — the only one in the program. Runs the body twice.
# ---------------------------------------------------------------------------
    addi  x26, x0, 2
loop_top:
    addi  x26, x26, -1
    addi  x27, x27, 1
    bne   x26, x0, loop_top

# ---------------------------------------------------------------------------
# terminate — must be last, and every path above falls through to here
# ---------------------------------------------------------------------------
    lui  t0, %hi(tohost)
    addi t0, t0, %lo(tohost)
    addi t1, x0, 1
    sw    t1, 0(t0)
park:
    jal   x0, park

# ---------------------------------------------------------------------------
# subroutines — reached only by jal, never fallen into
# ---------------------------------------------------------------------------
subr1:
    addi  x30, x0, 7
    jalr  x0, x1, 0               # return, rd = x0

subr2:
    addi  x31, x0, 8
    jalr  x2, x1, 0               # return, rd != 0 — x2 gets PC+4
