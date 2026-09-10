# riscv-cpu

A 5-stage pipelined RV32I core in SystemVerilog, verified instruction-by-instruction
against [Spike](https://github.com/riscv-software-src/riscv-isa-sim). Targets the Seeed
Spartan Edge Accelerator (`xc7s15ftgb196-1`).

```
$ ./scripts/run_tests.sh
  PASS  prog.S          rtl tests:   9, spike tests:   9, CPI: 1.556
  PASS  prog_nop.S      rtl tests:  23, spike tests:  23, CPI: 1.217
  PASS  coverage_nop.S  rtl tests: 287, spike tests: 287, CPI: 1.136
  PASS  coverage.S      rtl tests: 107, spike tests: 107, CPI: 1.364
  PASS  loaduse.S       rtl tests:  85, spike tests:  85, CPI: 1.412
  PASS  loads.S         rtl tests:  42, spike tests:  42, CPI: 1.071
  PASS  flushshadow.S   rtl tests:  40, spike tests:  40, CPI: 1.575
  PASS  hwtest.S        verdict driven onto led_green, LED: lit
REGRESSION: PASS (8/8)
```

Captured 2026-09-09 with case 7 of `sw/flushshadow.S` in place. Case 7 reads the shadow
instruction's destination register three instructions past the branch target, which is the
distance the earlier cases do not reach. It failed on the first run at retirement 35, reading
0x66 where 0xAA was architecturally correct, and passes now that `valid` is folded into
`wr_en` in `reg_file.sv`.

`hwtest.S` is the program the bitstream carries. It runs a spread of the datapath, accumulates
a pass/fail verdict in one register and stores that verdict to the peripheral window, so the LED
is the whole output on the board. It also runs under the regression, where a failure says which
check and on what cycle instead of just going dark.

**Status: L3 complete** (`l3-complete`). The pipeline executes the implemented RV32I
subset and matches Spike at every retirement, with control *and* data hazards resolved
in hardware, so no NOP padding is required.

**L2: complete** (`l2-complete`). The design implements on `xc7s15ftgb196-1` and **meets timing at
50 MHz** (WNS +0.215 ns, WHS +0.029 ns, zero failing endpoints out of 1465 setup and 1465 hold)
with the regression green. The bitstream loads over the onboard ESP32 via SPI, `sw/hwtest.S`
executes on the part, and a store to the peripheral window lights `led_green` and keeps it lit.

I closed L2 on 2026-09-10. The SPEC's *Done* criterion is "synthesizes and implements on a named
part, meets timing at a stated frequency, and still passes the testbench in simulation," and all
three are satisfied, with the peripheral store on the board as the observable proof. When I wrote
the level I had a UART and a character in a terminal in mind, but that was never what the document
asked for, and this board gives me no output path wide enough to make it the bar. The simple goal 
was that the cpu was implemented and programmed on the board. The best way to confirmed it worked
was a simple mmio led light. The UART has been delayed due to shifting proities in projects and 
school work.

---

## What works, and what doesn't

| | |
|---|---|
| RV32I base integer set | ✅ 37 of 37 |
| 5-stage pipeline (IF/ID/EX/MEM/WB) | ✅ |
| Control hazards — branch, JAL, JALR | ✅ flushed in hardware, 2-cycle penalty |
| Data hazards — EX/MEM and MEM/WB forwarding | ✅ |
| Load-use hazard — one-cycle interlock | ✅ |
| Synthesis and implementation, timing met at 50 MHz on an xc7s15 | ✅ |
| Runs from a bitstream on the board, LED driven from a peripheral store | ✅ |
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
*retire*, and Spike, which implements RISC-V and has no delay slots, never executes them. The retirement streams diverge and lockstep desynchronises. That is why branches
were flushed in hardware from L3a onward rather than padded.

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

`stage_wb` exists, and it did not always. The writeback value is selected in EX for
everything except loads, so for most instructions `mem_wb_q.temp_WBval` is already final by
the time it reaches WB. Loads are the exception: the block RAM hands back a whole word, and
the lane shift and sign extension have to happen somewhere. That work is `rtl/stage_wb.sv`,
and the block-RAM migration is what created the need for it.

The property I care about here survived that change, and it moved. It used to rest on
`mem_wb_q.WBval` being a single field in the pipeline register. It now rests on `WBval` being
a single net: `stage_wb` drives it combinationally in one `assign`, and both consumers read
that same net — `reg_file`'s write port at `top_lvl.sv:96` and the MEM/WB forward source at
`top_lvl.sv:141`. So the value that gets forwarded still cannot disagree with the value that
gets written, because there is only one value.

What changed is what the property depends on. A field in a register is singular no matter what
anyone does downstream. A net is singular only while nothing re-times it, and §4.4 of the
project page floats putting a flop between the block RAM output and the bypass to shorten the
critical path. That change would give the write port and the forward source different arrival
times and this guarantee would go with it. If I make it, the forwarding path needs re-deriving
first, not after.

Pipeline registers are packed structs (`if_id_t`, `id_ex_t`, `ex_mem_t`, `mem_wb_t`) in
`rtl/riscv_pkg.sv`, with control bundles (`ex_ctrl_t`, `mem_ctrl_t`, `wb_ctrl_t`) nested
inside them so the taper is enforced by the type system rather than remembered. All four
pipeline registers live in `top_lvl.sv`, five stages needing four boundaries between them, so
the entire stall and flush policy is eight adjacent lines.

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

Spike is the golden reference, an architectural simulator with no notion of pipeline,
cache, or clock. Its value is independence: expected values come from software written by
other people from the spec, not from the same understanding that produced the RTL.

The testbench parses `spike --log-commits` and compares **per retirement**, not per cycle.
It advances only when `mem_wb_q.valid` is high, so pipeline fill, flushes and stalls need
no special handling, and the testbench never learns how deep the pipeline is.

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

`sw/coverage.S` retires 107, covering all 37 base integer
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

Quote **1.36** — `coverage.S`, real code with hazards resolved in hardware. `prog.S` at
1.56 is nine instructions against four cycles of fill and is measuring pipeline depth, not
the design.

---

## Implementation

Vivado 2025.2, `xc7s15ftgb196-1`, speed grade −1, design state Routed. The numbers below are
from the routed `FPGA_top` build measured on 2026-08-22, and that same build is what runs on the
board. Utilization was read off the pre-wrapper `top_lvl` build; the divider and BUFG add about
one flop and one BUFG on top of it, which is why the LUT and FF figures here and in my
measurement notes differ slightly.

| | |
|---|---|
| Core clock | 50 MHz (20.000 ns) |
| WNS / WHS / WPWS | +0.215 ns / +0.029 ns / +4.500 ns |
| Failing endpoints | 0 of 1465 |
| LUT / FF / BRAM | 1261 (16%) / 384 (2%) / 1 (10%) |

The board oscillator is 100 MHz. `rtl/FPGA_top.sv` divides it by two in fabric and buffers
the result onto a global clock network; `top_lvl` stays clock-agnostic so the testbench,
which instantiates it directly and drives `clk`, needs no knowledge of any of this.

```tcl
create_clock -name clk -period 10.000 [get_ports clk_100]
create_generated_clock -name clk_in -source [get_ports clk_100] -divide_by 2 [get_pins bufg_core/O]
```

An MMCM would be required for an arbitrary frequency; 50 MHz is 100 divided by an integer,
so it isn't. The cost of the fabric divider is hold margin, because the clock now passes through
two cascaded BUFGs, roughly doubling insertion delay to 2.4–3.3 ns, which widens the
launch/capture divergence hold analysis sees. WHS +0.029 ns is met but thin, on a
zero-logic-level path (`ex_mem_q[temp_WBval]` → `mem_wb_q[temp_WBval]`) where there is no
logic delay to absorb skew. An MMCM's feedback loop compensates insertion delay and is the
fix if that ever goes negative.

### The critical path

```
data_cache BRAM output → stage_wb (variable shift by lane, sign-extend)
  → WBval → reg_file write-first bypass → id_ex_q.S1val
```

That is the writeback-to-decode bypass, and I want to state the result narrowly, because the
first version of this section did not. On `xc7s15ftgb196-1` at a 20 ns constraint, in this
build, the longest path is the load return: sixteen levels, 15.991 ns, roughly 70% route. That
is an unsurprising place for it to land, and unsurprising is as far as the measurement goes.

I had written that it is the path a textbook points at, which is backwards. The classic
five-stage critical path is the memory access itself, and it is the memory access because
textbook memory is asynchronous and the read happens combinationally inside one stage. Mine is
synchronous block RAM. The access moved into a stage boundary and its clock-to-out became a
fixed cost at the head of a different path instead. The logic share of the path shifted from
16% to 30% across that migration, which says the same thing from the other direction, since a
RAMB's clock-to-out is a large fixed cost a LUT-based read never pays.

So this path is critical because of a decision I made about memory, which is close to the
opposite of inevitable. Citing a textbook made a design-specific outcome sound like a law, and
it also closed the investigation early: two pieces of that path, the lane mux and the register
file bypass, are still unmeasured. Both are written up under §4.4 of the project page.

**Meeting 50 MHz is not the same as measuring Fmax.** The path measures 15.991 ns; against a
20 ns budget that should leave 4 ns of slack rather than 0.2. It doesn't, because the placer
and router optimize toward the constraint and stop. Achievable frequency under a tight
constraint is closer to 62 MHz. Measuring that properly means bypassing the divide-by-2 in
constraints, since the physical clock can only be 100 or 50.

---

## Memory map

| | |
|---|---|
| Link address / reset vector | `0x8000_0000` |
| Instruction memory | 512 words, partial decode |
| Data memory | 512 words, partial decode |
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
| **L2** — synthesis, timing closure, hardware bring-up | ✅ `l2-complete` — 50 MHz, runs on the board |
| **M** — multiply/divide (multi-cycle EX) | ← after L2 |
| **L4** — caches | |
| **L5** — CSRs, traps, privileged modes | |

L2 was deliberately re-sequenced after L3: block RAM has a registered read port, and a
single-cycle core has nowhere to put that cycle of latency. A 5-stage pipeline already has
a stage boundary in exactly that place — **the BRAM's own output register is the pipeline
register.** Doing synthesis first would have meant building a multicycle FSM purely to
absorb latency, then deleting it.

---

## Credits

All work on this project is my own except where listed here.

### AI assistance

**The regression harness, `scripts/run_tests.sh`, was written by Claude** (Anthropic). I had hit
a problem where my Makefile updated Spike's `commit.log` but not the copy Vivado's project was
reading, so the simulation kept scoring against a stale log. I wanted the whole flow out of the
Vivado GUI and into WSL, and I specified a script that would drive `xvlog`, `xelab` and `xsim`
directly. The failure modes it guards against are mine, in the sense that I hit every one of
them first: the stale snapshot that reported PASS on code which no longer compiled, the tool
exit codes that were being discarded, and the verdict rule that requires positive evidence of
success rather than the absence of the word FAIL. Model version and original prompt not
recorded.

**Everything in `sw/` except the Makefile's earliest form was written by Claude.** That is all
eight assembly test programs (`prog.S`, `prog_nop.S`, `coverage.S`, `coverage_nop.S`, `loads.S`,
`loaduse.S`, `flushshadow.S`, `hwtest.S`), the linker script `link.ld`, and the two Python
helpers `pad.py` and `bin2hex.py`. Worth being precise about what that does and
does not cover, because the programs are the thing the harness checks: **the harness is mine and
the programs it runs were generated.** What each program had to prove was my call every time, and
in most cases the reason a program exists is a hazard or a corner I had already found in the RTL.
Model versions and original prompts are not recorded for the earlier ones.

`flushshadow.S` case 7 is the clearest example of the split, and it is worth reading as one.
Claude wrote it on 2026-09-09 to expose the ungated write-first bypass in `reg_file.sv`. The
defect is not the model's find. I diagnosed it on 2026-08-19 while working through the flush
shadow, wrote the fix down as "fold `valid` into `wr_en`", noted that the hole was independently
reachable and that no test hit it, and then applied the gate to the clocked write and not to the
bypass. The case failed on its first run at retirement 35, reading `0x66` where `0xAA` was
architecturally correct, which is the value and the retirement the analysis predicted.

**Written by me:** the RTL in `rtl/`, the lockstep testbench in `tb/top_lvl_tb.sv` including
the `$sscanf` parsing of Spike's commit log and the retirement comparison, `constraints.xdc`, the
level scheme, and the debugging in every session log.

### Tools and references

| | |
|---|---|
| Golden reference | [Spike](https://github.com/riscv-software-src/riscv-isa-sim), the RISC-V ISA simulator. Expected values come from software other people wrote from the specification, which is the entire reason it is worth running. |
| Toolchain | [xPack `riscv-none-elf-gcc`](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack), prebuilt. |
| ISA | The RISC-V Instruction Set Manual, Volume I: Unprivileged Architecture. The decoder, the immediate formats and the branch conditions were written against it rather than against a diagram. |
| Board | [Seeed Spartan Edge Accelerator Board](https://github.com/SeeedDocument/Spartan-Edge-Accelerator-Board/tree/master) documentation, for the pin assignments and the ESP32 SPI programming flow. Pins were taken from their XDC rather than derived from the schematic. |
| Datapath overview | The Down To The Wire pipelining video, which is where I started. The control unit, the ALU control unit and the branch unit are mine; in the video the branch decision is an arrow labelled `br?` coming out of the ALU, and turning that into a module was the first real design decision I made. |
| Tools | Vivado 2025.2, WSL2. |
