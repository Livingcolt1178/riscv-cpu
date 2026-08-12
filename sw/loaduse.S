# ============================================================================
# loaduse.S — L3b load-use interlock coverage
#
# Spike is the oracle; nothing here encodes an expected value. This program
# only has to *exercise* the interlock and reach the tohost store.
#
# coverage.S has ZERO load-use pairs at distance <= 2, so it passes whether
# or not the interlock exists. This file is the one that can tell.
#
# Same constraints as coverage.S:
#   1. No initialized data — every load is preceded by a store to the same
#      address. A .data section is visible to Spike and invisible to the core.
#   2. Aligned only: word on 4-byte, half on 2-byte.
#   3. Never read back a byte/half that was not explicitly written. Every
#      sub-word read below lands inside a word written by a full sw.
#   4. Every path reaches the tohost store. It is the program's exit().
#
# Data scratch: 0x80000300..0x80000323. Clear of .text and of tohost.
#
# PREDICTED FAILURE with forwarding but no interlock:
#   first mismatch at section 1, `addi x10, x9, 1`.
#   The lw is in MEM, so the EX/MEM path fires and delivers ex_mem_q.WBval —
#   which for a LOAD is WB_sel_mux's `default: WBval = alu`, i.e. the
#   effective ADDRESS, not the data. Expect rd_data = 0x80000301.
#   Any other first-failure means something else is wrong.
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
# scratch base and seed data
# ---------------------------------------------------------------------------
    lui   x2,  0x80000
    addi  x2,  x2, 0x300          # x2 = 0x80000300

    lui   x5,  0x12345
    addi  x5,  x5, 0x678          # x5 = 0x12345678
    sw    x5,  0(x2)

    addi  x6,  x0, -1
    sw    x6,  4(x2)              # 0xFFFFFFFF

    lui   x7,  0x00007
    addi  x7,  x7, 0x0F0          # x7 = 0x000070F0
    sw    x7,  8(x2)              # all four bytes explicitly written

    sw    x2,  12(x2)             # a valid address, for base-register tests

    addi  x8,  x0, 0x2A
    sw    x8,  16(x2)             # 42

# ---------------------------------------------------------------------------
# 1. distance-1 load-use, loaded value as rs1        -> STALL
# ---------------------------------------------------------------------------
    lw    x9,  0(x2)
    addi  x10, x9, 1

# ---------------------------------------------------------------------------
# 2. distance-1 load-use, loaded value as rs2        -> STALL
# ---------------------------------------------------------------------------
    lw    x11, 0(x2)
    sub   x12, x0, x11

# ---------------------------------------------------------------------------
# 3. distance-1, same register on both operands      -> STALL, fwd_a + fwd_b
# ---------------------------------------------------------------------------
    lw    x13, 0(x2)
    add   x14, x13, x13

# ---------------------------------------------------------------------------
# 4. distance-2 load-use                             -> NO STALL, MEM/WB only
# ---------------------------------------------------------------------------
    lw    x15, 4(x2)
    addi  x16, x0, 7
    add   x17, x15, x16

# ---------------------------------------------------------------------------
# 5. two loads then a consumer of both
#    x19 is distance-1 (stalls); the stall pushes x18 out to the regfile
# ---------------------------------------------------------------------------
    lw    x18, 0(x2)
    lw    x19, 16(x2)
    add   x20, x18, x19

# ---------------------------------------------------------------------------
# 6. load with rd = x0 — no dependency exists        -> MUST NOT forward
#    with no rd != 0 guard, x21 comes out as 0x12345678 + 0x55
# ---------------------------------------------------------------------------
    lw    x0,  0(x2)
    addi  x21, x0, 0x55

# ---------------------------------------------------------------------------
# 7. load with no near dependent                     -> NO STALL
# ---------------------------------------------------------------------------
    lw    x22, 0(x2)
    addi  x23, x0, 3
    addi  x24, x0, 4
    add   x25, x22, x23

# ---------------------------------------------------------------------------
# 8. every load width consumed at distance 1         -> STALL each
#    word at 8(x2) = 0x000070F0
# ---------------------------------------------------------------------------
    lbu   x26, 8(x2)              # 0xF0
    addi  x27, x26, 1
    lb    x28, 8(x2)              # 0xF0 sign-extended
    addi  x29, x28, 1
    lhu   x30, 8(x2)              # 0x70F0
    addi  x31, x30, 1
    lh    x9,  10(x2)             # 0x0000, upper half of the same word
    addi  x10, x9, 1
    lw    x11, 8(x2)
    addi  x12, x11, 1

# ---------------------------------------------------------------------------
# 9. lw -> sw, loaded value is the STORE DATA (rs2, consumed in MEM)
#    the read-back proves the store wrote the forwarded value, not a stale one
# ---------------------------------------------------------------------------
    lw    x13, 0(x2)
    sw    x13, 20(x2)
    lw    x14, 20(x2)
    addi  x15, x14, 0

# ---------------------------------------------------------------------------
# 10. lw -> sw, loaded value is the ADDRESS BASE (rs1, consumed in EX)
# ---------------------------------------------------------------------------
    lw    x16, 12(x2)             # x16 = 0x80000300
    sw    x5,  24(x16)
    lw    x17, 24(x2)
    addi  x18, x17, 0

# ---------------------------------------------------------------------------
# 11. load -> load, loaded value is the next load's address
#     two interlocks back to back
# ---------------------------------------------------------------------------
    lw    x19, 12(x2)             # x19 = 0x80000300
    lw    x20, 0(x19)
    addi  x21, x20, 0

# ---------------------------------------------------------------------------
# 12. load feeding a BRANCH at distance 1, both directions
#     stall, then flush on the taken one
# ---------------------------------------------------------------------------
    lw    x22, 0(x2)
    beq   x22, x5, lu_taken       # TAKEN
    addi  x23, x0, 0x7AD          # must not execute
lu_taken:
    lw    x24, 0(x2)
    bne   x24, x5, lu_skip        # NOT TAKEN
    addi  x25, x0, 0x11
lu_skip:
    addi  x26, x0, 0x22

# ---------------------------------------------------------------------------
# 13. load feeding a JALR base at distance 1
#     exercises the forward into target_address_constructor, not the ALU
# ---------------------------------------------------------------------------
    lui   x27, %hi(lu_jt)
    addi  x27, x27, %lo(lu_jt)
    sw    x27, 28(x2)
    lw    x28, 28(x2)
    jalr  x1,  x28, 0
    addi  x29, x0, 0x7AD          # must not execute
lu_jt:
    addi  x30, x0, 0x33

# ---------------------------------------------------------------------------
# 14. interlock inside a loop with a taken branch every iteration
#     also a distance-2 branch operand, which is what caught the last bug
# ---------------------------------------------------------------------------
    addi  x31, x0, 3
    sw    x31, 32(x2)
lu_loop:
    lw    x9,  32(x2)
    addi  x9,  x9, -1
    sw    x9,  32(x2)
    bne   x9,  x0, lu_loop

# ---------------------------------------------------------------------------
# 15. load-use immediately after a branch target — flush then stall
# ---------------------------------------------------------------------------
    jal   x0, lu_after
    addi  x10, x0, 0x7AD          # must not execute
lu_after:
    lw    x11, 0(x2)
    addi  x12, x11, 1

# ---------------------------------------------------------------------------
# terminate — every path above falls through to here
# ---------------------------------------------------------------------------
    lui  t0, %hi(tohost)
    addi t0, t0, %lo(tohost)
    addi t1, x0, 1
    sw    t1, 0(t0)
park:
    jal   x0, park
