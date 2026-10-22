# Part C: static timing analysis of the synthesized netlist with OpenSTA.
# Typical corner only (tt_025C_1v80).
#
# Run from the repository root:
#   sta sta/sta.tcl                      T = 10 ns (default below)
#   STA_PERIOD=<Tmin> sta sta/sta.tcl    T = Tmin, to confirm slack is close to 0
#
# Tmin = T - WNS, Fmax = 1000 / Tmin MHz.

set lib $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Clock period T in ns
set T 10.0
if {[info exists ::env(STA_PERIOD)]} {
    set T $::env(STA_PERIOD)
}

# 1. Cell timing library
read_liberty $lib

# 2. Gate-level netlist from Part B
read_verilog synth/mult_array_netlist.v
link_design mult_array

# 3. Clock with period T
create_clock -name clk -period $T [get_ports clk]

# 4. Inputs (except clk) arrive 1 ns after the clock edge
set_input_delay 1.0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]

# 5. Outputs must be valid 1 ns before the next clock edge
set_output_delay 1.0 -clock clk [all_outputs]

# 6. Worst setup slack
puts "Clock period T = $T ns"
report_worst_slack -max -digits 3

# 7. Critical (worst setup) path report
report_checks -path_delay max -digits 3 > sta/mult_array_timing.rpt

exit
