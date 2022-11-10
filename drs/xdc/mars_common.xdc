set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]

#create_property iob port -type string
#set_property IOB TRUE [all_inputs]
#set_property IOB TRUE [all_outputs]

set_property IOSTANDARD LVCMOS25 [get_ports {emio_*}]

set_property IOSTANDARD LVCMOS25 [get_ports {drs_*}]

set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i[*]}]

set_property IOSTANDARD LVDS_25 [get_ports mt_trigger_i_*]

set_property IOSTANDARD LVCMOS25 [get_ports ext_trigger_i*]

set_property IOSTANDARD LVCMOS25 [get_ports loss_of_lock_i]

# set_property IOSTANDARD LVDS_25 [get_ports {gpio_p[*]}]
# set_property IOSTANDARD LVDS_25 [get_ports {gpio_n[*]}]

set_property IOSTANDARD LVDS_25 [get_ports clock_i_*]

set_property IOSTANDARD LVCMOS25 [get_ports {gfp_s*}]

set_property IOSTANDARD LVCMOS25 [get_ports led*]

set_property SLEW SLOW [get_ports drs_*_o]

set_property DRIVE 4 [get_ports drs_*_o]
set_property DRIVE 6 [get_ports drs_srclk_o]

set_property PULLUP true [get_ports mt_trigger_i_p]
set_property PULLDOWN true [get_ports mt_trigger_i_n]

set_property PULLDOWN true [get_ports ext_trigger_i]
set_property PULLDOWN true [get_ports gfp_sclk]
set_property PULLDOWN true [get_ports gfp_sdat]
