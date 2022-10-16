# 33MHz inputs
set_input_delay -clock [get_clocks drs_clk_clock_wizard] -min 3.000 [get_ports -filter { NAME =~  "*adc*" && DIRECTION == "IN" }]
set_input_delay -clock [get_clocks drs_clk_clock_wizard] -max 5.000 [get_ports -filter { NAME =~  "*adc*" && DIRECTION == "IN" }]
set_input_delay -clock [get_clocks drs_clk_clock_wizard] -min 1.000 [get_ports -filter { NAME =~  "*srout*" && DIRECTION == "IN" }]
set_input_delay -clock [get_clocks drs_clk_clock_wizard] -max 5.000 [get_ports -filter { NAME =~  "*srout*" && DIRECTION == "IN" }]

set_input_delay -clock [get_clocks drs_clk_clock_wizard] -max 5.000 [get_ports -filter { NAME =~  "*gfp_s*" && DIRECTION == "IN" }]

# 33MHz outputs

set_output_delay -clock [get_clocks drs_clk_clock_wizard] -min 1.000 [get_ports {drs_addr_o[*]}]
set_output_delay -clock [get_clocks drs_clk_clock_wizard] -max 7.00 [get_ports {drs_addr_o[*]}]

set_output_delay -clock [get_clocks drs_clk_clock_wizard] -min 1.000 [get_ports drs_denable_o]
set_output_delay -clock [get_clocks drs_clk_clock_wizard] -max 7.00 [get_ports drs_denable_o]

set_output_delay -clock [get_clocks drs_clk_clock_wizard] -min 1.000 [get_ports drs_rsrload_o]
set_output_delay -clock [get_clocks drs_clk_clock_wizard] -max 7.00 [get_ports drs_rsrload_o]

set_output_delay -clock [get_clocks drs_clk_clock_wizard] -min 1.000 [get_ports drs_srin_o]
set_output_delay -clock [get_clocks drs_clk_clock_wizard] -max 7.00 [get_ports drs_srin_o]

set_output_delay -clock [get_clocks drs_clk_clock_wizard] -min 1.000 [get_ports drs_dwrite_o]
set_output_delay -clock [get_clocks drs_clk_clock_wizard] -max 7.00 [get_ports drs_dwrite_o]

set_output_delay -clock [get_clocks drs_clk_clock_wizard] -min 1.000 [get_ports drs_srclk_o]
set_output_delay -clock [get_clocks drs_clk_clock_wizard] -max 7.00 [get_ports drs_srclk_o]

set_input_delay -clock [get_clocks drs_clk_clock_wizard] -min 1.000 [get_ports drs_plllock_i]
set_input_delay -clock [get_clocks drs_clk_clock_wizard] -max 7.00 [get_ports drs_plllock_i]

set_input_delay -clock [get_clocks drs_clk_clock_wizard] -min 1.000 [get_ports drs_dtap_i]
set_input_delay -clock [get_clocks drs_clk_clock_wizard] -max 7.00 [get_ports drs_dtap_i]

set_output_delay -clock [get_clocks drs_clk_clock_wizard] -min 1.000 [get_ports drs_nreset_o]
set_output_delay -clock [get_clocks drs_clk_clock_wizard] -max 7.00 [get_ports drs_nreset_o]

set_false_path -from [get_ports drs_dtap_i]
set_false_path -from [get_ports drs_plllock_i]
set_false_path -to   [get_ports drs_nreset_o]

#set_min_delay -from [get_ports ext_trigger_i] -to [get_ports drs_dwrite_o] 8
# DWRITE Special Output
set_max_delay -datapath_only -from [get_ports ext_trigger_i] -to [get_ports drs_dwrite_o] 19

# false path for dma ILA
# set_false_path \
#     -from [get_pins {daq_inst/*/C}] \
#     -to [get_pins {ps_interface_inst/dma_controller_inst/debug.ila_s2mm_inst/U0/*/D}]

set_max_delay \
    -to   [get_pins {ps_interface_inst/dma_controller_inst/synchronizer_inst/sync_gen.gen_ff[0].s_resync_reg[1]/D}] 8.0
