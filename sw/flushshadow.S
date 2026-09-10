# ============================================================================
# AUTHORSHIP
#   Case 7 and its banner were written by Claude (claude-opus-5) on 2026-09-09,
#   to a task Nicholas set: add a case to this file that exposes the ungated
#   write-first bypass in reg_file.sv. The defect itself is not the model's
#   find. Nicholas diagnosed it and wrote the fix down in his own measurement
#   notes on 2026-08-19, in the table under "the rule is 'gate the claim,' not
#   'gate the effect'", where the row for the register-file write-first bypass
#   reads "fold valid into wr_en" and the line under it records that the hole is
#   independently reachable and that no test hits it. This case is that test.
#
#   RUN 2026-09-10. It failed on its first run at retirement 35, reading 0x66
#   where 0xAA was architecturally correct, and passes now that valid is folded
#   into wr_en in reg_file.sv. The expected values below were derived from
#   reading the RTL before the run and matched what the run produced. The point of
#   the case is to fail on the current tree; if it passes on first run, the
#   cycle accounting in its banner is wrong and should be re-derived before
#   anything is concluded about reg_file.sv.
#
#   Cases 1 through 6 were also written by Claude, in earlier sessions. Model
#   versions and original prompts are not recorded for those.
# ============================================================================

# ============================================================================
# flushshadow.S — a taken redirect must not let its shadow commit
#
# Regression test for the bug found 2026-08-19. A jump resolved in EX has two
# instructions already fetched behind it. Before the block-RAM migration,
# `if_id_q <= '0` zeroed the *instruction* as well as `valid`, and a zeroed
# instruction decodes to op_class = NOP with we_reg = 0 — the kill was implicit
# in the data. With a registered instruction memory the instruction lives in the
# BRAM output register, out of that flop's reach, so the second shadow slot
# leaks through fully decoded carrying valid = 0. Nothing gated on valid, so it
# committed.
#
# `coverage.S` caught this only by luck of layout: its `jal x1, jal_tgt` happened
# to land the second shadow slot on another jump. Shift the program by one
# instruction and it passes with the bug in. This file makes the coverage
# deliberate.
#
# Each case is built the same way, because the leak is INVISIBLE TO THE RETIRE
# STREAM — the bench only records retires where mem_wb_q.valid is 1, and the
# leaked instruction has valid = 0. So a shadow write produces no extra retire;
# it silently corrupts state. Every case must therefore READ THE STATE BACK
# afterwards to make the corruption observable.
#
#   1. put a known value somewhere
#   2. jump over two instructions that would overwrite it
#   3. read it back — Spike expects the original
#
# All three redirect sources are covered (JAL, taken branch, JALR) and all three
# commit points (register write, memory write, PC redirect).
#
# Case 7 is a different shape and reads the state back three instructions past
# the target rather than at it. A leaked instruction can corrupt a later
# instruction's operand without committing anything of its own, so blocking the
# commit points is not on its own enough. See the banner on that case.
#
# Same constraints as coverage.S / loads.S:
#   1. No initialised data — every load is preceded by a store to the address.
#   2. Misalignment not implemented — words stay 4-byte aligned.
#   3. Spike is the oracle. Comments state intent; nothing encodes an expected
#      value.
#   4. Every path reaches the tohost store.
#
# Data scratch: 0x80000340..0x80000343. Clear of coverage.S (0x300..0x30B) and
# loads.S (0x320..0x32F).
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
    addi  x2,  x2, 0x340          # x2 = 0x80000340, scratch base

# ---------------------------------------------------------------------------
# case 1 — JAL shadow must not write a register
#
# Commit point: reg_file write enable. If either shadow slot commits, x5 holds
# 0x22 or 0x33 and the read-back diverges.
# ---------------------------------------------------------------------------
    addi  x5,  x0, 0x11           # victim, known good
    jal   x0, c1_done             # taken, skips the next two
    addi  x5,  x0, 0x22           # shadow slot 1 — must not commit
    addi  x5,  x0, 0x33           # shadow slot 2 — must not commit  <- the leak
c1_done:
    addi  x6,  x5, 0              # observable: x6 must be 0x11

# ---------------------------------------------------------------------------
# case 2 — JAL shadow must not write memory
#
# Commit point: data_cache write enable. A shadow store leaves no retire of its
# own, so the load is what exposes it.
# ---------------------------------------------------------------------------
    lui   x7,  0xABCDE
    addi  x7,  x7, 0x123          # x7 = 0xABCDE123
    sw    x7,  0(x2)              # known good word
    addi  x8,  x0, -1             # 0xFFFFFFFF, the poison
    jal   x0, c2_done
    sw    x8,  0(x2)              # shadow slot 1 — must not commit
    sw    x8,  0(x2)              # shadow slot 2 — must not commit
c2_done:
    lw    x9,  0(x2)              # observable: must still be 0xABCDE123

# ---------------------------------------------------------------------------
# case 3 — JAL shadow must not redirect
#
# Commit point: ex_redirect. This is the one that actually fired in coverage.S,
# and it is the only case where the divergence shows up as a PC mismatch rather
# than a data mismatch. If a shadow jump commits, control lands in c3_trap.
# ---------------------------------------------------------------------------
    jal   x0, c3_done
    jal   x0, c3_trap             # shadow slot 1 — must not commit
    jal   x0, c3_trap             # shadow slot 2 — must not commit
c3_done:
    addi  x10, x0, 1              # reached normally
    jal   x0, c3_end
c3_trap:
    addi  x10, x0, 0x7FF          # reachable only via a committed shadow jump
c3_end:

# ---------------------------------------------------------------------------
# case 4 — taken BRANCH shadow
#
# A branch redirect is a different source term than a jump (op_class == BRANCH
# && br) and reaches ex_redirect by a different path. Cover it separately.
# ---------------------------------------------------------------------------
    addi  x11, x0, 5
    addi  x12, x0, 0x44           # victim
    beq   x11, x11, c4_done       # always taken
    addi  x12, x0, 0x55           # shadow slot 1 — must not commit
    addi  x12, x0, 0x66           # shadow slot 2 — must not commit
c4_done:
    addi  x13, x12, 0             # observable: x13 must be 0x44

# ---------------------------------------------------------------------------
# case 5 — JALR shadow
#
# The third redirect source, and the only one whose target comes from a register
# rather than the PC — so it is also the only one whose shadow depends on a
# forwarded operand being right.
#
#   +0  auipc  x14, 0        x14 = this address
#   +4  addi   x14, x14, 24  target = +24 = c5_done
#   +8  addi   x15, x0, 0x77
#   +12 jalr   x0, x14, 0
#   +16 shadow slot 1
#   +20 shadow slot 2
#   +24 c5_done
# ---------------------------------------------------------------------------
    auipc x14, 0
    addi  x14, x14, 24            # target address, two past the shadow
    addi  x15, x0, 0x77           # victim
    jalr  x0, x14, 0              # taken
    addi  x15, x0, 0x88           # shadow slot 1 — must not commit
    addi  x15, x0, 0x99           # shadow slot 2 — must not commit
c5_done:
    addi  x16, x15, 0             # observable: x16 must be 0x77

# ---------------------------------------------------------------------------
# case 6 — shadow of a backward branch
#
# Every redirect above jumps forward. A backward target is a different immediate
# sign and a different fetch pattern; cheap to cover, and it is the shape a loop
# actually has.
# ---------------------------------------------------------------------------
    addi  x17, x0, 2
    addi  x18, x0, 0xAA           # victim
    jal   x0, c6_entry
c6_top:
    addi  x19, x0, 1              # loop body, reached only from the backward branch
    jal   x0, c6_done
c6_entry:
    addi  x17, x17, -1
    bne   x17, x0, c6_top         # taken backward
    addi  x18, x0, 0xBB           # shadow slot 1 — must not commit
    addi  x18, x0, 0xCC           # shadow slot 2 — must not commit
c6_done:
    addi  x20, x18, 0             # observable: x20 must be 0xAA

# ---------------------------------------------------------------------------
# case 7 — the leaked shadow must not reach the register file's read ports
#
# Cases 1 through 6 check that a shadow instruction never *commits*: no register
# write, no memory write, no redirect. This case checks something else. A leaked
# instruction can hand a wrong value to a later instruction without committing
# anything itself, because `reg_file`'s write-first bypass is driven by `wr_en`
# and `wr_en` does not include `valid`:
#
#     reg_file.sv:22   assign wr_en = (we && WBreg != 0);        <- no valid
#     reg_file.sv:25   if (wr_en && WBreg == S1reg) S1val = WBval;
#     reg_file.sv:40   if (wr_en && valid) regs[WBreg] <= WBval;  <- valid here
#
# One control signal, two consumers, only one of them gated. The clocked write
# is safe. The combinational read port is not.
#
# Why cases 1-6 cannot see it. They all read the victim at their own `cN_done`
# label, which is target+0. The leak is only visible three instructions later.
# Counting from the cycle the jump resolves in EX as T:
#
#   T     ex_redirect fires. flush_id forces id_inst to 0, killing shadow 1.
#   T+1   flush_ex has cleared id_ex_q.valid, so ex_redirect is already low.
#         id_inst is now shadow 2, decoded normally, and if_id_q.valid is 0.
#   T+2   shadow 2 is in EX with valid=0 and its payload intact. Target+0 is
#         in ID.
#   T+3   shadow 2 is in MEM. Target+1 is in ID.
#   T+4   shadow 2 is in mem_wb_q: valid=0, wb.we_reg=1, wb.rd=x21. Target+2
#         is in ID, and its register read goes through the bypass.
#
# So the consumer has to sit at target+2. `forwarding_unit` is correctly gated
# on mem_wb_q.valid and stands aside, which is what leaves the bypass to answer.
#
# The jump is `jal x0` on purpose. With a nonzero rd the flush also parks a
# stale copy of the jump itself in id_ex_q for one cycle, which reaches mem_wb_q
# at T+3 and would poison target+1 as well. That copy carries the jump's own
# correct pc+4, so it is harmless, but it would blur which slot this case is
# actually testing. Writing rd=x0 makes wr_en 0 for it and leaves one window.
#
# The mechanism does not depend on the redirect source. Shadow 2 leaks out of
# the fetch shadow, not out of the branch unit, so a taken branch and a JALR
# behave identically here and are already covered for commit in cases 4 and 5.
#
# Registers: x21 is the victim and the shadow's rd. x22 and x23 are spacers and
# do nothing except occupy target+0 and target+1. x24 is the observable.
# ---------------------------------------------------------------------------
    addi  x21, x0, 0xAA           # victim, known good
    jal   x0, c7_done             # taken, skips the next two
    addi  x21, x0, 0x55           # shadow slot 1 — killed in ID by id_inst
    addi  x21, x0, 0x66           # shadow slot 2 — leaks, valid=0, rd=x21
c7_done:
    addi  x22, x0, 0x01           # target+0 — spacer
    addi  x23, x0, 0x02           # target+1 — spacer
    addi  x24, x21, 0             # target+2 — observable: x24 must be 0xAA
                                  # with the bypass ungated it reads 0x66

# ---------------------------------------------------------------------------
# exit
# ---------------------------------------------------------------------------
    lui   x29, %hi(tohost)
    addi  x29, x29, %lo(tohost)
    addi  x30, x0, 1
    sw    x30, 0(x29)
park:
    jal   x0, park
