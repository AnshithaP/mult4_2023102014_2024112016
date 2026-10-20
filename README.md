# 4-bit Array Multiplier: RTL to GDSII (SKY130)

Digital VLSI Design team assignment.

## Team

| Name | Roll number | Parts |
|------|-------------|-------|
| Anshitha Penubolu | 2023102014 | A (RTL and verification), B (synthesis) |
| TEAMMATE NAME | 2024112016 | C (static timing analysis), D (physical design) |

## Environment

IIC-OSIC-TOOLS Docker container, SKY130 PDK (`sky130A`), standard cell library `sky130_fd_sc_hd`, typical corner `tt_025C_1v80`.
All commands are run from the repository root inside the container unless stated otherwise.

```bash
iverilog -V | head -1
yosys -V
sta -version
echo $PDK_ROOT $PDK
```

## Part A: RTL design and verification

RTL simulation:

```bash
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
gtkwave mult.vcd
```

Result: `PASS: 256 vectors checked, 0 errors`

Error test (temporarily changed `sum` in `rtl/full_adder.v` to `a ^ b`, re-ran the two commands below, then undid the change):

```bash
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
```

Result: `FAIL: 256 vectors checked, 95 errors`

Worked example: A = 9 (last digit of Anshitha's roll number 2023102014 is 4, 4 + 5 = 9), B = 7, P = 63.

## Part B: Logic synthesis

```bash
yosys -c synth/synth.tcl
```

Gate-level (netlist) simulation:

```bash
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
  tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls
```

Result: `PASS: 256 vectors checked, 0 errors`

## Part C: Static timing analysis

```bash
sta sta/sta.tcl
```

(Add every run here, with the clock period used.)

## Part D: Physical design

```bash
cd pnr
librelane config.json
```

| Attempt | CLOCK_PERIOD (ns) | Setup slack (ns) | DRC | LVS | Result |
|---------|-------------------|------------------|-----|-----|--------|
| 1 | | | | | |

Final run files copied from `runs/<run>/final/` to `pnr/metrics.json` and `pnr/mult_array.gds`.
