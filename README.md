# 4-bit Array Multiplier: RTL to GDSII (SKY130)

A 4-bit × 4-bit unsigned array multiplier (16 AND gates, 12 full adders, registered inputs and output), taken from RTL to GDSII with open-source tools on SkyWater SKY130 (`sky130_fd_sc_hd`).

## Team

| Name | Roll number |
|------|-------------|
| Anshitha Penubolu | 2023102014 |
| Lavanya Patil | 2024112016 |

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

`sta/sta.tcl` reads `synth/mult_array_netlist.v` with the typical-corner library (`sky130_fd_sc_hd__tt_025C_1v80.lib`). The clock period is 10 ns unless `STA_PERIOD` is set, so the same script does both runs:

```bash
sta sta/sta.tcl                    # T = 10 ns: worst slack 7.020 ns, so Tmin = 10 - 7.020 = 2.98 ns
STA_PERIOD=2.98 sta sta/sta.tcl    # T = Tmin: worst slack 0.000 ns
```

`sta/mult_array_timing.rpt` is the report from the second run (T = 2.98 ns).

### Part D: Physical design

`CLOCK_PERIOD` starts at 1.2 × Tmin = 1.2 × 2.98 = 3.576 ns, rounded up to the next 0.5 ns = 4.0 ns. Each time the flow stopped with setup violations, `CLOCK_PERIOD` in `pnr/config.json` was raised by 0.5 ns and the flow was run again. LibreLane uses `$PDK`, which defaults to `ihp-sg13g2` in the 2026.10 container, so select SKY130 first:

```bash
sak-pdk sky130A
cd pnr
librelane config.json      # once per attempt in the table below
cp runs/RUN_2026-10-21_19-13-06/final/metrics.json .
cp runs/RUN_2026-10-21_19-13-06/final/gds/mult_array.gds .
klayout mult_array.gds
```

Every run. Setup slack is `timing__setup__ws` from `metrics.json`: the worst of LibreLane's 9 STA corners, which was the slow corner `max_ss_100C_1v60` in every run. The typical-corner value (`nom_tt_025C_1v80`) is in brackets. DRC errors are Magic / KLayout.

| Attempt | Run folder | CLOCK_PERIOD (ns) | Setup slack (ns) | DRC errors | LVS errors | Result |
|---------|------------|-------------------|------------------|------------|------------|--------|
| 1 | RUN_2026-10-21_18-53-39 | 4.0 | -1.957 (tt +0.883) | 0 / 0 | 0 | stopped: setup violations at ss corners |
| 2 | RUN_2026-10-21_18-57-48 | 4.5 | -1.457 (tt +1.383) | 0 / 0 | 0 | stopped: setup violations at ss corners |
| 3 | RUN_2026-10-21_19-00-58 | 5.0 | -0.957 (tt +1.883) | 0 / 0 | 0 | stopped: setup violations at ss corners |
| 4 | RUN_2026-10-21_19-04-08 | 5.5 | -0.456 (tt +2.382) | 0 / 0 | 0 | stopped: setup violations at ss corners |
| 5 | RUN_2026-10-21_19-07-09 | 6.0 | -0.128 (tt +2.818) | 0 / 0 | 0 | stopped: setup violations at ss corners |
| 6 | RUN_2026-10-21_19-10-12 | 6.5 | -0.157 (tt +3.089) | 0 / 0 | 0 | stopped: setup violations at ss corners |
| 7 | RUN_2026-10-21_19-13-06 | 7.0 | +0.076 (tt +3.519) | 0 / 0 | 0 | flow complete (final run) |

Attempts 5 and 6 gained less than 0.5 ns because LibreLane re-synthesizes for every run with the clock period as the ABC delay target (`retime -D`), so the netlist changed between runs.
