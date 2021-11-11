set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property -dict {IOSTANDARD LVCMOS33 PULLDOWN True} \
    [get_ports clk_i*];

set_property -dict {IOSTANDARD LVCMOS33 PULLDOWN True} \
    [get_ports lt_data_i*];

set_property -dict {IOSTANDARD LVCMOS33 \
                        SLEW FAST} \
    [get_ports rb_data_o*];

set_property -dict {IOSTANDARD LVCMOS33} \
    [get_ports *rgmii*];

set_property -dict {IOSTANDARD LVCMOS33 \
                        SLEW FAST} \
    [get_ports sump_o*];

set_max_delay -datapath_only \
    -from [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT0]] \
    -to [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT2]] 4.0

set_max_delay -datapath_only \
    -to [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT0]] \
    -from [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT2]] 4.0
