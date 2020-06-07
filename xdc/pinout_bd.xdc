# this is a copy of the pinout file compatible with the weird names that the bd wrapper creates

#create_property iob port -type string
#set_property IOB TRUE [all_inputs]
#set_property IOB TRUE [all_outputs]

set_property IOSTANDARD LVCMOS25 [get_ports drs_denable_o_0]
set_property IOSTANDARD LVCMOS25 [get_ports drs_dtap_i_0]
set_property IOSTANDARD LVCMOS25 [get_ports drs_dwrite_o_0]
set_property IOSTANDARD LVCMOS25 [get_ports drs_plllock_i_0]
set_property IOSTANDARD LVCMOS25 [get_ports drs_nreset_o_0]
set_property IOSTANDARD LVCMOS25 [get_ports drs_rsrload_o_0]
set_property IOSTANDARD LVCMOS25 [get_ports drs_srclk_o_0]
set_property IOSTANDARD LVCMOS25 [get_ports drs_srin_o_0]
set_property IOSTANDARD LVCMOS25 [get_ports drs_srout_i_0]
#set_property IOSTANDARD  LVCMOS25 [get_ports drs_wrsin_o_0]
#set_property IOSTANDARD  LVCMOS25 [get_ports drs_wsrout_i_0]

set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[9]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[10]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[11]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {adc_data_i_0[13]}]

set_property IOSTANDARD LVCMOS25 [get_ports {drs_addr_o_0[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {drs_addr_o_0[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {drs_addr_o_0[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {drs_addr_o_0[3]}]

set_property IOSTANDARD LVDS_25 [get_ports {trigger_i_0_p}]
set_property IOSTANDARD LVDS_25 [get_ports {trigger_i_0_n}]

set_property IOSTANDARD LVDS_25 [get_ports {gpio_n_0[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_n_0[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_n_0[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_n_0[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_n_0[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_n_0[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_n_0[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_n_0[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_n_0[8]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_n_0[9]}]
#set_property IOSTANDARD LVDS_25 [get_ports {gpio_n[10]}]

set_property IOSTANDARD LVDS_25 [get_ports {gpio_p_0[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_p_0[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_p_0[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_p_0[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_p_0[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_p_0[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_p_0[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_p_0[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_p_0[8]}]
set_property IOSTANDARD LVDS_25 [get_ports {gpio_p_0[9]}]
#set_property IOSTANDARD LVDS_25 [get_ports {gpio_p[10]}]

set_property IOSTANDARD LVDS_25 [get_ports clock_i_0_n]
set_property IOSTANDARD LVDS_25 [get_ports clock_i_0_p]

################################################################################
# Pinouts
################################################################################

set_property PACKAGE_PIN E17 [get_ports {trigger_i_0_p}]; # IO_B35_L3_AD1_E17_P
set_property PACKAGE_PIN D18 [get_ports {trigger_i_0_n}]; # IO_B35_L3_AD1_D18_N

set_property PACKAGE_PIN D19 [get_ports {gpio_p_0[0]}]; # IO_B35_L4_D19_P
set_property PACKAGE_PIN D20 [get_ports {gpio_n_0[0]}]; # IO_B35_L4_D20_N
set_property PACKAGE_PIN C20 [get_ports {gpio_p_0[1]}]; # IO_B35_L1_AD0_C20_P
set_property PACKAGE_PIN B20 [get_ports {gpio_n_0[1]}]; # IO_B35_L1_AD0_B20_N
set_property PACKAGE_PIN B19 [get_ports {gpio_p_0[2]}]; # IO_B35_L2_AD8_B19_P
set_property PACKAGE_PIN A20 [get_ports {gpio_n_0[2]}]; # IO_B35_L2_AD8_A20_N
set_property PACKAGE_PIN H15 [get_ports {gpio_p_0[3]}]; # IO_B35_L19_H15_P
set_property PACKAGE_PIN G15 [get_ports {gpio_n_0[3]}]; # IO_B35_L19_VREF_G15_N
set_property PACKAGE_PIN M17 [get_ports {gpio_p_0[4]}]; # IO_B35_L8_AD10_M17_P
set_property PACKAGE_PIN M18 [get_ports {gpio_n_0[4]}]; # IO_B35_L8_AD10_M18_N
set_property PACKAGE_PIN K17 [get_ports {gpio_p_0[5]}]; # IO_B35_L12_MRCC_K17_P
set_property PACKAGE_PIN K18 [get_ports {gpio_n_0[5]}]; # IO_B35_L12_MRCC_K18_N
set_property PACKAGE_PIN K16 [get_ports {gpio_p_0[6]}]; # IO_B35_L24_AD15_K16_P
set_property PACKAGE_PIN J16 [get_ports {gpio_n_0[6]}]; # IO_B35_L24_AD15_J16_N
set_property PACKAGE_PIN G17 [get_ports {gpio_p_0[7]}]; # IO_B35_L16_G17_P
set_property PACKAGE_PIN G18 [get_ports {gpio_n_0[7]}]; # IO_B35_L16_G18_N
set_property PACKAGE_PIN F16 [get_ports {gpio_p_0[8]}]; # IO_B35_L6_F16_P
set_property PACKAGE_PIN F17 [get_ports {gpio_n_0[8]}]; # IO_B35_L6_VREF_F17_N
set_property PACKAGE_PIN E18 [get_ports {gpio_p_0[9]}]; # IO_B35_L5_AD9_E18_P
set_property PACKAGE_PIN E19 [get_ports {gpio_n_0[9]}]; # IO_B35_L5_AD9_E19_N

#DRS4
#set_property PACKAGE_PIN T17      [get_ports drs_wsrin_o_0] # IO_B34_L20_T17_P
set_property PACKAGE_PIN R18 [get_ports drs_denable_o_0]; # IO_B34_L20_R18_N
set_property PACKAGE_PIN T12 [get_ports drs_dwrite_o_0]; # IO_B34_L2_T12_P
set_property PACKAGE_PIN U12 [get_ports drs_plllock_i_0]; # IO_B34_L2_U12_N
set_property PACKAGE_PIN V16 [get_ports drs_dtap_i_0]; # IO_B34_L18_V16_P
set_property PACKAGE_PIN W16 [get_ports {drs_addr_o_0[3]}]; # IO_B34_L18_W16_N
set_property PACKAGE_PIN R16 [get_ports {drs_addr_o_0[2]}]; # IO_B34_L19_R16_P
set_property PACKAGE_PIN L20 [get_ports drs_nreset_o_0]; # IO_B35_L9_L20_N
set_property PACKAGE_PIN K19 [get_ports {drs_addr_o_0[1]}]; #IO_B35_L10_K19_P
set_property PACKAGE_PIN J19 [get_ports {drs_addr_o_0[0]}]; # IO_B35_L10_J19_N

set_property PACKAGE_PIN H18 [get_ports drs_rsrload_o_0]; # IO_B35_L14_SRCC_H18_N
set_property PACKAGE_PIN J18 [get_ports drs_srclk_o_0]; # IO_B35_L14_SRCC_J18_P

set_property PACKAGE_PIN G19 [get_ports drs_srin_o_0]; # IO_B35_L18_AD13_G19_P
set_property PACKAGE_PIN G20 [get_ports drs_srout_i_0]; # IO_B35_L18_AD13_G20_N
#set_property PACKAGE_PIN F19 [get_ports drs_wsrout_i_0] # IO_B35_L15_AD12_F19_P

set_property PACKAGE_PIN U18 [get_ports clock_i_0_p]; # IO_B34_L12_MRCC_U18_P
set_property PACKAGE_PIN U19 [get_ports clock_i_0_n]; # IO_B34_L12_MRCC_U19_N

# ADC Data
set_property PACKAGE_PIN L19 [get_ports {adc_data_i_0[0]}]; # IO_B35_L9_L19_P
set_property PACKAGE_PIN M20 [get_ports {adc_data_i_0[1]}]; # IO_B35_L7_M20_N
set_property PACKAGE_PIN M19 [get_ports {adc_data_i_0[2]}]; # IO_B35_L7_M19_P
set_property PACKAGE_PIN N16 [get_ports {adc_data_i_0[3]}]; # IO_B35_L21_N16_N
set_property PACKAGE_PIN N15 [get_ports {adc_data_i_0[4]}]; # IO_B35_L21_N15_P
set_property PACKAGE_PIN W19 [get_ports {adc_data_i_0[5]}];; # IO_B34_L22_W19_N
set_property PACKAGE_PIN W18 [get_ports {adc_data_i_0[6]}]; # IO_B34_L22_W18_P
set_property PACKAGE_PIN Y19 [get_ports {adc_data_i_0[7]}]; # IO_B34_L17_Y19_N
set_property PACKAGE_PIN Y18 [get_ports {adc_data_i_0[8]}]; # IO_B34_L17_Y18_P
set_property PACKAGE_PIN Y17 [get_ports {adc_data_i_0[9]}]; # IO_B34_L7_Y17_N
set_property PACKAGE_PIN Y16 [get_ports {adc_data_i_0[10]}]; # IO_B34_L7_Y16_P
set_property PACKAGE_PIN W15 [get_ports {adc_data_i_0[11]}]; # IO_B34_L10_W15_N
set_property PACKAGE_PIN V15 [get_ports {adc_data_i_0[12]}]; # IO_B34_L10_V15_P
set_property PACKAGE_PIN R17 [get_ports {adc_data_i_0[13]}]; # IO_B34_L19_R17_N
