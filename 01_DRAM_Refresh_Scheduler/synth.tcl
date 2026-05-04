# =====================================================================
# synth.tcl  --  Vivado out-of-context synth driver
#
# Runs synthesis twice with two parameter configurations and dumps
# utilisation + timing reports for each.
#
# Usage:
#   vivado -mode batch -source synth.tcl
#
# Adjust -part for whichever FPGA you target. Default: Artix-7 (xc7a35t).
# =====================================================================

set TARGET_PART  "xc7a35tcpg236-1"
set TOP          "refresh_scheduler_top"
set CLK_PERIOD   10.0   ;# 100 MHz target

set RTL_FILES [list \
    refresh_timer.sv \
    refresh_fsm.sv \
    apb_slave.sv \
    Top_Integration.sv \
]

# ------------------------------------------------------------------
# Helper: synthesise one configuration
# ------------------------------------------------------------------
proc run_config {tag part top clk_period rtl generics} {
    puts "============================================================"
    puts " CONFIG: $tag"
    puts " GENERICS: $generics"
    puts "============================================================"

    create_project -in_memory -part $part

    foreach f $rtl { read_verilog -sv $f }

    # Build a synthetic timing constraint inline
    set xdc_path "./_clk_${tag}.xdc"
    set fp [open $xdc_path "w"]
    puts $fp "create_clock -name PCLK -period $clk_period \[get_ports PCLK\]"
    close $fp
    read_xdc $xdc_path

    # Run synthesis with the requested generic overrides
    eval synth_design -top $top -part $part -mode out_of_context $generics

    report_utilization      -file "util_${tag}.rpt"
    report_timing_summary   -file "timing_${tag}.rpt"

    close_project
}

# ------------------------------------------------------------------
# Config 1 : narrow / shallow
# ------------------------------------------------------------------
run_config "cfg1_narrow" $TARGET_PART $TOP $CLK_PERIOD $RTL_FILES \
    {-generic ADDR_WIDTH=8 -generic DATA_WIDTH=32 -generic CNT_WIDTH=16 -generic TIMEOUT_CYCLES=32}

# ------------------------------------------------------------------
# Config 2 : wide / deep
# ------------------------------------------------------------------
run_config "cfg2_wide"   $TARGET_PART $TOP $CLK_PERIOD $RTL_FILES \
    {-generic ADDR_WIDTH=8 -generic DATA_WIDTH=64 -generic CNT_WIDTH=32 -generic TIMEOUT_CYCLES=128}

puts "Done. Reports: util_cfg1_narrow.rpt, timing_cfg1_narrow.rpt, util_cfg2_wide.rpt, timing_cfg2_wide.rpt"
