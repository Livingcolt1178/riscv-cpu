# riscv-cpu

A single-cycle RV32I core in SystemVerilog, targeting the Spartan Edge Accelerator.

Currently at **L1** — proving the single-cycle core executes RV32I correctly against
[Spike](https://github.com/riscv-software-src/riscv-isa-sim) as a golden reference.
Synthesis is L2 and a separate activity.

---

## Layout

```
rtl/        SystemVerilog sources
tb/         Testbenches
sw/         Test programs, linker script, generated hex
scripts/    Vivado project generation
vivado/     Generated Vivado project — gitignored, do not commit
```

The Vivado `.xpr` is a database containing machine-absolute paths, not a source file.
It is not version controlled. `scripts/build_project.tcl` regenerates it.

---

## Building the Vivado project

```bash
vivado -mode batch -source scripts/build_project.tcl
```

Safe to delete `vivado/` and re-run at any time. This is also how to move the project
to another machine.

---

## Building the test program

Requires a RISC-V bare-metal toolchain. On Windows, use WSL2 — the toolchain and Spike
do not build natively on Windows, though Vivado does.

**Toolchain:** [xPack `riscv-none-elf-gcc`](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack)
prebuilt (linux-x64), unpacked and added to `PATH`. Do not build from source — it takes
an hour and is unnecessary.

```bash
cd sw && make
```

Produces `program.hex`, one 32-bit little-endian word per line, which
`rtl/Instruction_cache.sv` loads via `$readmemh`.

`program.hex` **is** committed despite being generated, so simulation works on clone
without standing up the toolchain first.

---

## Running against the reference model

**Spike** is the golden reference — an architectural simulator that models register and
memory state per the ISA spec, with no notion of pipeline, cache, or clock. It is not
cycle-accurate and does not try to be. Its value is independence: expected values come
from software written by other people from the spec, rather than from the same
understanding that produced the RTL.

```bash
spike --isa=RV32IM -d sw/prog.elf
```

In interactive mode:

```
until pc 0 <addr>     run until PC reaches addr (0 = hart number)
reg 0 <name>          read a register — ABI names only, `ra` not `x1`
reg 0                 dump all 32
```

---

## Memory map

Programs link at `0x8000_0000` — Spike's default memory base. Instruction memory decodes
only `PC[9:2]`, so `0x8000_0000` and `0x0` address the same word and the core's reset
vector stays at `0`. This keeps Spike on its defaults with no `-m` flag.

| | |
|---|---|
| Link address | `0x80000000` |
| Core reset vector | `0` |
| `tohost` | `0x800003FC` |
| Instruction memory | 256 words |

`tohost` is the HTIF termination convention: the program writes a non-zero value there
to signal completion. `1` means pass; `(n << 1) | 1` means fail on test `n`. Spike's
front end watches that address and exits; the testbench watches the same address and
stops the clock. No trap hardware or CSRs required.

---

## Status

| Stage | |
|---|---|
| 0 — elaborates and simulates | ✅ |
| 1 — executes | ✅ |
| 3 — toolchain | ✅ |
| 4 — Spike as oracle | ⬜ |
| 5 — coverage | ⬜ |
| 6 — L1 complete | ⬜ |

Verified so far: `addi` with small positive immediates, and `jal`. Remaining ALU ops,
loads and stores, branch conditions, `jalr`, `lui`, and `auipc` are untested.