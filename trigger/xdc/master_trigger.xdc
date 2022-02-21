set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_max_delay -datapath_only \
    -from [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT0]] \
    -to [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT2]] 4.0

set_max_delay -datapath_only \
    -to [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT0]] \
    -from [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT2]] 4.0
