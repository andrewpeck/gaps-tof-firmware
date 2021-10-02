set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]

#create_property iob port -type string
#set_property IOB TRUE [all_inputs]
#set_property IOB TRUE [all_outputs]

set_property IOSTANDARD LVCMOS25 [get_ports {drs_*}]

set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i[*]}]

set_property IOSTANDARD LVDS_25 [get_ports ext_trigger_i_*]

# set_property IOSTANDARD LVDS_25 [get_ports {gpio_p[*]}]
# set_property IOSTANDARD LVDS_25 [get_ports {gpio_n[*]}]

set_property IOSTANDARD LVDS_25 [get_ports clock_i_*]

set_property IOSTANDARD LVCMOS25 [get_ports {gfp_s*}]
