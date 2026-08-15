# riscv-cpu

A 5-stage pipelined RV32I core in SystemVerilog, verified instruction-by-instruction
against [Spike](https://github.com/riscv-software-src/riscv-isa-sim). Targets the Seeed
Spartan Edge Accelerator (`xc7s15ftgb196-1`).

```
$ ./scripts/run_tests.sh
  PASS  prog.S          rtl tests:   9, spike tests:   9, CPI: 1.556
  PASS  prog_nop.S      rtl tests:  23, spike tests:  23, CPI: 1.217
  PASS  coverage_nop.S  rtl tests: 271, spike tests: 271, CPI: 1.114
  PASS  coverage.S      rtl tests:  99, spike tests:  99, CPI: 1.313
  PASS  loaduse.S       rtl tests:  85, spike tests:  85, CPI: 1.412
REGRESSION: PASS (5/5)
```

**Status: L3 complete** (`l3-complete`). The pipeline executes the implemented RV32I
subset and matches Spike at every retirement, with control *and* data hazards resolved
in hardware — no NOP padding required.

---

## What works, and what doesn't

| | |
|---|---|
| RV32I base integer set | ✅ 37 of 37 |
| 5-stage pipeline (IF/ID/EX/MEM/WB) | ✅ |
| Control hazards — branch, JAL, JALR | ✅ flushed in hardware, 2-cycle penalty |
| Data hazards — EX/MEM and MEM/WB forwarding | ✅ |
| Load-use hazard — one-cycle interlock | ✅ |
| Synthesis / timing closure | ❌ L2 |
| M extension, caches, CSRs and traps | ❌ M / L4 / L5 |



### Hazards are resolved in hardware

Forwarding is a mux per operand at the entrance to EX, sourcing from `ex_mem_q` (the
producer one instruction ahead) or `mem_wb_q` (two ahead), selected by a forwarding unit
that matches destination against source register *before* applying the newer-wins
priority. Both operands are decided independently. The forwarded value feeds the ALU, the
target-address constructor and the store-data path from a single point, so JALR bases and
store data cannot be forgotten.

A load's result does not exist until the end of MEM, so the one case forwarding cannot
cover is a load consumed by the very next instruction. The hazard detection unit holds the
PC and IF/ID and bubbles ID/EX for one cycle, converting that into a distance-2 dependency
the existing MEM/WB path already handles. The bubble is also what keeps the EX/MEM path
quiet during that cycle, so the forwarding unit needs no special case for loads.

### Why NOP-padded programs are still in the regression

`sw/pad.py` inserts NOPs to separate dependent instructions, which is how the datapath was
brought up before any hazard hardware existed (L3a). That scaffold is retired, but
`prog_nop.S` and `coverage_nop.S` stay in the suite: they are the same programs with the
hazards removed, so if forwarding ever starts producing wrong values, the padded and
unpadded variants disagree and the pair localises the fault. They cost nothing to keep.

Worth stating precisely, because it isn't obvious: **padding never could fix *control*
hazards.** NOPs behind a taken branch are architecturally harmless but they still
*retire*, and Spike — implementing RISC-V, which has no delay slots — never executes
them. The retirement streams diverge and lockstep desynchronises. That is why branches
were flushed in hardware from L3a onward rather than padded.

---

## Layout

```
rtl/        SystemVerilog sources — four stage wrappers over leaf modules
tb/         Lockstep testbench
sw/         Test programs, padding generator, linker script
scripts/    run_tests.sh — the regression
build/      Simulation scratch — gitignored
vivado/     Generated project — gitignored, do not commit
```

There is no `stage_wb`. The writeback value is selected in EX for everything except loads
and in MEM for those, so `mem_wb_q.WBval` is the final value by the time it reaches WB and
the stage collapses to the register-file write port. That is not tidiness — it is what
makes the MEM/WB forward source a single field, which makes it structurally impossible for
the value that gets forwarded to disagree with the value that gets written.

Pipeline registers are packed structs (`if_id_t`, `id_ex_t`, `ex_mem_t`, `mem_wb_t`) in
`rtl/riscv_pkg.sv`, with control bundles (`ex_ctrl_t`, `mem_ctrl_t`, `wb_ctrl_t`) nested
inside them so the taper is enforced by the type system rather than remembered. All four
flops live in `top_lvl.sv`, so the entire stall and flush policy is eight adjacent lines.

A zeroed register struct is a NOP bubble — `NOP` is enum 0, both write-enables are 0, and
`valid` is 0 — which makes reset, flush, and the retire signal (`mem_wb_q.valid`) fall out
of the type definition.

---

## Running the regression

```bash
./scripts/run_tests.sh
```

For each program: rebuild the ELF, run Spike for the commit log, generate `program.hex`,
then compile and simulate the RTL. One verdict, nonzero exit on failure.

**Requires WSL2 on Windows.** The toolchain and Spike are Linux-only; Vivado is invoked
across the boundary through `cmd.exe`.

- **Toolchain:** [xPack `riscv-none-elf-gcc`](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack)
  prebuilt, on `PATH`. Do not build from source.
- **Spike:** built from source, on `PATH`.
- **Vivado:** set `VIVADO_BIN` if it isn't at the default path.

No `.xpr` is involved. Standalone `xvlog`/`xelab`/`xsim` read from the working directory;
a Vivado project's `sim_1` fileset copies files at elaboration and will silently serve a
stale `commit.log`.

---

## Verification

Spike is the golden reference — an architectural simulator with no notion of pipeline,
cache, or clock. Its value is independence: expected values come from software written by
other people from the spec, not from the same understanding that produced the RTL.

The testbench parses `spike --log-commits` and compares **per retirement**, not per cycle.
It advances only when `mem_wb_q.valid` is high, so pipeline fill, flushes and stalls need
no special handling — the testbench never learns how deep the pipeline is.

Six fields are compared at the MEM/WB boundary, ordered cheapest-to-interpret first so
that the earliest failure is the most localising one:

```
pc → instruction word → rd → rd_data → mem_addr → mem_data
```

Fields that exist only for the checker (`inst`, store data, `fct3` past MEM) live in a
`trace_t` nested inside `mem_wb_t`. Nesting matters: a standalone trace register would
need its own stall and flush arms kept in agreement forever, and when they diverged the
harness would report a plausible mismatch on plausible data with no signal that it was
lying.

`sw/coverage.S` is 108 instructions and retires 99, covering 34 of the 37 base integer
instructions under three constraints: every load is preceded by a store (the core has no
initialised data memory), halfword accesses stay aligned, and every path reaches the
`tohost` store.

`sw/loaduse.S` targets the interlock specifically, because `coverage.S` contains **zero**
load-use pairs at distance ≤ 2 and therefore passes whether or not the interlock exists.
It has 20 distance-1 pairs that must stall and 2 distance-2 pairs that must not, across
all five load widths, with the loaded value used as rs1, as rs2, as store data, as a store
address base, as the address of a following load, as a branch operand in both directions,
and as a JALR base. Two negative controls check that stalls *don't* fire: a load into `x0`,
and a load whose consumer is three instructions later.

### CPI

`clk_count / retirements`, measured from reset release to the `tohost` store. The
arithmetic closes: `loaduse.S` is 85 retirements + 20 load-use stalls + 5 taken transfers
× 2 flush cycles + 4 cycles of pipeline fill = 119 against 120 measured, the residual
being one edge of sampling lag. That the stall term lands exactly on the number of
distance-1 pairs in the program makes CPI a second, independent witness that the interlock
fires when it should and only when it should.

Quote **1.31** — `coverage.S`, real code with hazards resolved in hardware. `prog.S` at
1.56 is nine instructions against four cycles of fill and is measuring pipeline depth, not
the design.

---

## Memory map

| | |
|---|---|
| Link address / reset vector | `0x8000_0000` |
| Instruction memory | 1024 words, partial decode |
| Data memory | 256 words, partial decode |
| `tohost` / `fromhost` | `0x8000_13F0` / `0x8000_13F8` |

Both memories decode only the low address bits, folding the `0x8000_0000` window down to
the array. The reset vector matches the link address because JAL, JALR and AUIPC write
**the PC itself** into `rd` — a core booting at `0` while Spike runs at `0x8000_0000`
disagrees with the reference on all three.

`tohost` is the HTIF termination convention: the program writes a non-zero value there to
signal completion, `1` meaning pass. Spike's front end watches that address and exits; the
testbench watches the same address and stops. No trap hardware or CSRs required. Assembly
sources use `%hi(tohost)`/`%lo(tohost)` so `link.ld` is the single source of truth.

### Known non-conformances (V1)

All three trap in real RV32I and are deferred to L5:

- **Misaligned data access** — `data_cache` ignores it.
- **Misaligned instruction fetch** — JALR clears bit 0 but not bit 1, and the fetch fold
  discards `pc[1:0]`, so a 2-mod-4 target silently fetches the wrong word.
- **Illegal instruction** — an unrecognised opcode decodes to a silent NOP.

---

## Roadmap

| | |
|---|---|
| **L1** — single-cycle RV32I vs Spike | ✅ `l1-complete` |
| **L3a** — pipeline, hazards deferred by padding | ✅ `l3a-complete` |
| **L3b** — forwarding + load-use interlock | ✅ `l3-complete` |
| **M** — multiply/divide (multi-cycle EX) | ← next |
| **L2** — synthesis and timing closure | |
| **L4** — caches | |
| **L5** — CSRs, traps, privileged modes | |

L2 was deliberately re-sequenced after L3: block RAM has a registered read port, and a
single-cycle core has nowhere to put that cycle of latency. A 5-stage pipeline already has
a stage boundary in exactly that place — **the BRAM's own output register is the pipeline
register.** Doing synthesis first would have meant building a multicycle FSM purely to
absorb latency, then deleting it.
