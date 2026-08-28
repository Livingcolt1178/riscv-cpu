# ============================================================================
# hwtest.S -- the hardware bring-up program. This is the one the bitstream
# carries.
#
# Every other program in sw/ is checked per-retirement against Spike, where
# thousands of signals are observable. On the board there is exactly one:
# led_green. So this program runs a spread of the datapath, accumulates a
# verdict, and drives that verdict onto the LED.
#
#   led_green HIGH  -- every check below passed
#   led_green DARK  -- a check failed, OR the core never reached the end,
#                      OR it was never configured, OR reset is stuck asserted
#
# One sticky bit cannot separate those. That is a property of the board, not a
# defect in the program -- which is why this same file also runs under the
# regression, where a failure says which check and on what cycle.
# ============================================================================

.section .tohost, "aw", @progbits
.align 3
.global tohost
tohost:   .dword 0
.align 3
.global fromhost
fromhost: .dword 0

.section .text
.global _start

# Peripheral window is [0x1000, 0x8000_0000) -- see MMIO_unit.sv. 0x20000000
# also has to be a page Spike has mapped and does not already use; SPIKE_MEM in
# the Makefile lists the collisions. These two must agree.
.equ LED_ADDR,  0x20000000

# Data address must be OUTSIDE the peripheral window or the store becomes an
# MMIO write instead of a dmem write. dmem index is addr[10:2] = 256 here,
# clear of the tohost word at index 252.
.equ DATA_ADDR, 0x80000400

_start:
    li   s0, 1                  # verdict. Any failed check clears it to 0.

# ---- 1. arithmetic, backward branch, EX->EX forwarding --------------------
# sum 1..10 = 55. Each add consumes the previous add's result in the very next
# cycle, so the whole loop is a forwarding chain.
    li   t0, 0                  # accumulator
    li   t1, 1                  # i
    li   t2, 11                 # limit
sum_loop:
    add  t0, t0, t1
    addi t1, t1, 1
    blt  t1, t2, sum_loop

    li   t3, 55
    beq  t0, t3, chk_shift
    li   s0, 0

# ---- 2. shifts and logic --------------------------------------------------
chk_shift:
    li   t0, 0xABCDE123
    srli t1, t0, 16
    li   t2, 0x0000ABCD
    beq  t1, t2, chk_and
    li   s0, 0

chk_and:
    li   t0, 0xF0F0F0F0
    li   t1, 0x0FF00FF0
    and  t2, t0, t1
    li   t3, 0x00F000F0
    beq  t2, t3, chk_mem
    li   s0, 0

# ---- 3. store/load round trip: word, halfword, byte -----------------------
# The lw feeds the beq in the next instruction, so this is also a load-use
# interlock at distance 1 -- the case loaduse.S exists to cover.
chk_mem:
    li   t0, DATA_ADDR
    li   t1, 0x12345678
    sw   t1, 0(t0)
    lw   t2, 0(t0)
    beq  t1, t2, chk_lbu
    li   s0, 0

chk_lbu:
    lbu  t3, 0(t0)              # little-endian: lowest byte is 0x78
    li   t4, 0x78
    beq  t3, t4, chk_lhu
    li   s0, 0

chk_lhu:
    lhu  t3, 2(t0)              # upper halfword is 0x1234
    li   t4, 0x1234
    beq  t3, t4, chk_sb
    li   s0, 0

# Byte enables: sb must change lane 1 and nothing else.
# 0x12345678 with byte[1] := 0xAA  ->  0x1234AA78
chk_sb:
    li   t1, 0xAA
    sb   t1, 1(t0)
    lw   t2, 0(t0)
    li   t3, 0x1234AA78
    beq  t2, t3, chk_jal
    li   s0, 0

# ---- 4. jal link register and jalr return ---------------------------------
chk_jal:
    jal  ra, subr               # ra <- address of the li below
    li   t0, 7
    beq  a0, t0, verdict
    li   s0, 0
    j    verdict

subr:
    li   a0, 7
    jalr x0, 0(ra)

# ---- 5. report on the only output the board has ---------------------------
# LED_IO latches high on a nonzero store and low on a zero store, so s0 drives
# the LED directly -- a failed run darkens it rather than leaving it stale.
verdict:
    li   t0, LED_ADDR
    sw   s0, 0(t0)

# ---- 6. tell the testbench the program is done ----------------------------
# Must be last. top_lvl_tb breaks its retirement loop on the tohost store, so
# anything after this point is never simulated.
    lui  t0, %hi(tohost)
    addi t0, t0, %lo(tohost)
    li   t1, 1
    sw   t1, 0(t0)

hang:
    j    hang
