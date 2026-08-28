# ============================================================================
# loads.S — load lane / sign-extension coverage, and store byte-enable isolation
#
# Companion to coverage.S. Written because coverage.S has two blind spots that
# the MEM-stage rewrite (byte enables + BRAM + WB-side load align) lands in:
#
#   a. Its byte loads only ever touch lanes 0 and 1. Lanes 2 and 3 of the load
#      lane mux are never read.
#   b. Its only signed halfword is -2 = 0xFFFE, where bit 7 and bit 15 are both
#      1. A sign extender that replicates bit 7 instead of bit 15 returns the
#      correct answer there, so that bug passes coverage.S.
#
# Same constraints coverage.S is written under:
#   1. Harvard core with no $readmemh on the data array, so there is NO
#      initialised data. Every load is preceded by a store to the same address.
#      Every block below opens with a full-word SW so all four lanes are
#      defined before any sub-word read.
#   2. data_cache ignores misalignment (documented V1 decision) — halfwords
#      stay 2-byte aligned, words 4-byte aligned.
#   3. Spike is the oracle. Nothing here encodes an expected value; the
#      comments state intent, the lockstep bench does the comparing.
#   4. Every path reaches the tohost store. It is the program's exit().
#
# Data scratch: 0x80000320..0x8000032F. Clear of .text below and of
# coverage.S's 0x300..0x30B, so both programs can share one memory map.
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

    lui   x2,  0x80000
    addi  x2,  x2, 0x320          # x2 = 0x80000320, scratch base

# ---------------------------------------------------------------------------
# byte loads — all four lanes, both signs
#
# word A = 0x0180007F
#   lane3 = 0x01 (+1)     lane2 = 0x80 (-128)
#   lane1 = 0x00 ( 0)     lane0 = 0x7F (+127)
#
# lane0 and lane2 are the signed boundary pair: +127 is the largest value a
# byte extends to unchanged, -128 the one that must extend to all-ones above.
# ---------------------------------------------------------------------------
    lui   x5,  0x01800
    addi  x5,  x5, 0x07F          # x5 = 0x0180007F
    sw    x5,  0(x2)

    lb    x6,  0(x2)              # lane 0: +127
    lbu   x7,  0(x2)              # lane 0:  127
    lb    x8,  1(x2)              # lane 1:    0
    lb    x9,  2(x2)              # lane 2: -128   <- new lane, sign extended
    lbu   x10, 2(x2)              # lane 2:  128   <- new lane, zero extended
    lb    x11, 3(x2)              # lane 3:   +1   <- new lane
    lbu   x12, 3(x2)              # lane 3:    1

# word B = 0x80030201
#   lane3 = 0x80 (-128)   lane2 = 0x03
#   lane1 = 0x02          lane0 = 0x01
#
# Lane 3 with the sign bit set. The top lane is where an off-by-one in the
# lane mux or a shift that drops off the end shows up, and coverage.S never
# reads it at all.
# ---------------------------------------------------------------------------
    lui   x13, 0x80030
    addi  x13, x13, 0x201         # x13 = 0x80030201
    sw    x13, 4(x2)

    lb    x14, 7(x2)              # lane 3: -128   <- new lane, sign extended
    lbu   x15, 7(x2)              # lane 3:  128
    lb    x16, 6(x2)              # lane 2:   +3

# ---------------------------------------------------------------------------
# halfword sign-extension discriminator
#
# Both halfwords below have bit 7 != bit 15, so replicating the wrong one is
# observable. This is the block coverage.S cannot substitute for.
#
# word C = 0xFF7F0080
#   half@+2 = 0xFF7F  (bit15 = 1, bit7 = 0)
#   half@+0 = 0x0080  (bit15 = 0, bit7 = 1)
# ---------------------------------------------------------------------------
    lui   x17, 0xFF7F0
    addi  x17, x17, 0x080         # x17 = 0xFF7F0080
    sw    x17, 8(x2)

    lh    x18, 8(x2)              # 0x0080 -> 0x00000080, NOT 0xFFFF0080
    lhu   x19, 8(x2)              # 0x00000080
    lh    x20, 10(x2)             # 0xFF7F -> 0xFFFFFF7F, NOT 0x0000FF7F
    lhu   x21, 10(x2)             # 0x0000FF7F

# ---------------------------------------------------------------------------
# store byte enables — the lanes that must NOT change
#
# No load test can catch a write enable that is too wide: a store that also
# clobbers its neighbours still reads back correctly at the lane it meant to
# write. Each step here writes one sub-word field into a known background
# pattern and reads the WHOLE WORD back, so an over-wide enable surfaces as
# corruption in a lane nothing touched.
# ---------------------------------------------------------------------------
    lui   x22, 0x5A5A5
    addi  x22, x22, 0x555         # x22 = 0x5A5A5555, background pattern
    sw    x22, 12(x2)

    addi  x23, x0, -1             # low byte = 0xFF
    sb    x23, 15(x2)             # lane 3 only
    lw    x24, 12(x2)             # 0xFF5A5555 — lanes 2,1,0 must survive

    addi  x25, x0, 0x33
    sb    x25, 13(x2)             # lane 1 only
    lw    x26, 12(x2)             # 0xFF5A3355 — lanes 3,2,0 must survive

    lui   x27, 0x1
    addi  x27, x27, 0x234         # x27 = 0x1234
    sh    x27, 14(x2)             # lanes 3:2 only
    lw    x28, 12(x2)             # 0x12343355 — lanes 1,0 must survive

# ---------------------------------------------------------------------------
# exit
# ---------------------------------------------------------------------------
    lui   x29, %hi(tohost)
    addi  x29, x29, %lo(tohost)
    addi  x30, x0, 1
    sw    x30, 0(x29)
loop:
    jal   x0, loop
