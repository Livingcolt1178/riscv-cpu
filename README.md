# riscv-cpu

A 5-stage pipelined RV32I core in SystemVerilog, verified instruction-by-instruction
against [Spike](https://github.com/riscv-software-src/riscv-isa-sim). Targets the Seeed
Spartan Edge Accelerator (`xc7s15ftgb196-1`).

```
$ ./scripts/run_tests.sh
  PASS  prog_nop.S      rtl tests:  22, spike tests: 4995
  PASS  coverage_nop.S  rtl tests: 270, spike tests: 4995
L1 REGRESSION: PASS (2/2)
```

**Status: L3a.** The pipeline executes all of RV32I and matches Spike at every
retirement. Control hazards are handled in hardware. **Data hazards are not** — see below.

---

## What works, and what doesn't

| | |
|---|---|
| RV32I instruction set | ✅ all 47 instructions |
| 5-stage pipeline (IF/ID/EX/MEM/WB) | ✅ |
| Control hazards — branch, JAL, JALR | ✅ flushed in hardware, 2-cycle penalty |
| Data hazards — forwarding, load-use interlock | ❌ **L3b** |
| Synthesis / timing closure | ❌ L2 |
| M extension, caches, CSRs and traps | ❌ L3b+ / L4 / L5 |

### ⚠️ The core is not currently a conformant RV32I implementation

There is no forwarding network and no interlock, so a dependent instruction must be
separated from its producer by two instruction slots. Test programs are therefore
**NOP-padded** — `sw/pad.py` inserts two NOPs after every instruction. This is the
original MIPS philosophy (*Microprocessor without Interlocked Pipeline Stages*), and
RISC-V explicitly rejected it: the spec requires hardware to resolve data hazards.

Padding is a scaffold, not a destination. `sw/coverage.S` (unpadded) is kept in the tree
as the target that L3b must pass; only its padded variant is in the regression today.

Worth stating precisely, because it isn't obvious: **padding cannot fix *control*
hazards.** NOPs behind a taken branch are architecturally harmless but they still
*retire*, and Spike — implementing RISC-V, which has no delay slots — never executes
them. The retirement streams diverge and lockstep desynchronises. That is why branches
are flushed in hardware rather than padded.

---

## Layout

```
rtl/        SystemVerilog sources — five stage wrappers over leaf modules
tb/         Lockstep testbench
sw/         Test programs, padding generator, linker script
scripts/    run_tests.sh — the regression
build/      Simulation scratch — gitignored
vivado/     Generated project — gitignored, do not commit
```

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
It advances only when `mem_wb_q.valid` is high, so pipeline fill, flushes, and (later)
stalls need no special handling — the testbench never learns how deep the pipeline is.

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

`sw/coverage.S` exercises all 47 RV32I instructions in 106 instructions, under three
constraints: every load is preceded by a store (the core has no initialised data memory),
halfword accesses stay aligned, and every path reaches the `tohost` store.

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
| **L3b** — forwarding + load-use interlock | ← next |
| **M** — multiply/divide (multi-cycle EX) | |
| **L2** — synthesis and timing closure | |
| **L4** — caches | |
| **L5** — CSRs, traps, privileged modes | |

L2 was deliberately re-sequenced after L3: block RAM has a registered read port, and a
single-cycle core has nowhere to put that cycle of latency. A 5-stage pipeline already has
a stage boundary in exactly that place — **the BRAM's own output register is the pipeline
register.** Doing synthesis first would have meant building a multicycle FSM purely to
absorb latency, then deleting it.
