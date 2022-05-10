set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]


set_max_delay -datapath_only \
    -from [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT0]] \
    -to [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT2]] 4.0

set_max_delay -datapath_only \
    -to [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT0]] \
    -from [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT2]] 4.0

set_property -dict { PACKAGE_PIN "K21" IOSTANDARD LVCMOS33} [get_ports {rst_button_i}]; # IO_0_14 Sch = RSTPIN
set_property -dict { PACKAGE_PIN "F22" IOSTANDARD LVCMOS33} [get_ports {sys_clk_i}]; # IO_L12P_T1_MRCC_14 Sch = CLK1

set_property PACKAGE_PIN "Y6" [get_ports {sump_o}]; # choose an unused pin

set_property IOSTANDARD LVDS [get_ports fb_clk_*]
set_property IOSTANDARD LVDS [get_ports clk_*]

# set_property IOSTANDARD          [get_ports sda]
# set_property IOSTANDARD          [get_ports scl]

set_property -dict {IOSTANDARD LVCMOS33} \
    [get_ports *rgmii*];

set_property IOSTANDARD LVDS [get_ports lt_data_i*]
set_property IOSTANDARD LVCMOS33 [get_ports rb_data_o*]

set_property IOSTANDARD LVCMOS15 [get_ports lvs_sync_dsi]
set_property IOSTANDARD LVCMOS15 [get_ports lvs_sync_ccb]
set_property IOSTANDARD LVCMOS15 [get_ports dsi_on]
set_property IOSTANDARD LVCMOS15 [get_ports clk_src_sel]

set_property IOSTANDARD LVCMOS33 [get_ports hk_cs_n*]
set_property IOSTANDARD LVCMOS33 [get_ports hk_clk]
set_property IOSTANDARD LVCMOS33 [get_ports hk_dout]
set_property IOSTANDARD LVCMOS33 [get_ports hk_din]

set_property IOSTANDARD LVCMOS15 [get_ports ext_io*]
set_property IOSTANDARD LVCMOS15 [get_ports ext_out*]

# Bank 34 --> 1.5V
# Bank 33 --> 1.5V
# Bank 32 --> VADJ
# Bank 16 --> VADJ
# Bank 15 --> VADJ
# Bank 14 --> VCC3V3
# Bank 13 --> VCC3V3
# Bank 12 --> VADJ
# Bank 0  --> VCC3V3
#
 #set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 34]];
