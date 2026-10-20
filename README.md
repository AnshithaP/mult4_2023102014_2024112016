# 4-bit Array Multiplier: RTL to GDSII (SKY130)

A 4-bit × 4-bit unsigned array multiplier (16 AND gates, 12 full adders, registered inputs and output), taken from RTL to GDSII with open-source tools on SkyWater SKY130 (`sky130_fd_sc_hd`).

## Team

| Name | Roll number |
|------|-------------|
| Anshitha Penubolu | 2023102014 |
| TEAMMATE NAME | 2024112016 |

## Repository layout

```
README.md
rtl/      full_adder.v, mult_array.v
tb/       tb_mult.v
synth/    synth.tcl, mult_array_netlist.v, mult_array_stat.rpt
sta/      sta.tcl, mult_array_timing.rpt
pnr/      config.json, metrics.json, mult_array.gds
report/   report.pdf
```

## Commands, in order

All commands are run from the repository root inside the IIC-OSIC-TOOLS container unless stated otherwise.

### Setup

```bash
iverilog -V | head -1
yosys -V
sta -version
echo $PDK_ROOT $PDK
```

### Part A: RTL simulation

```bash
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
gtkwave mult.vcd
```

Error test (with `sum` in `rtl/full_adder.v` temporarily changed to `a ^ b`, then changed back):

```bash
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
```

### Part B: Synthesis and netlist simulation

```bash
yosys -c synth/synth.tcl
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
  tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls
```

### Part C: Static timing analysis

Run with the clock period in `sta/sta.tcl` set to 10 ns, then again with it set to Tmin:

```bash
sta sta/sta.tcl
```

### Part D: Physical design

```bash
cd pnr
librelane config.json
cp runs/<final-run>/final/metrics.json .
cp runs/<final-run>/final/gds/mult_array.gds .
klayout mult_array.gds
```

Every run:

| Attempt | CLOCK_PERIOD (ns) | Setup slack (ns) | DRC errors | LVS errors |
|---------|-------------------|------------------|------------|------------|
| 1 | | | | |
