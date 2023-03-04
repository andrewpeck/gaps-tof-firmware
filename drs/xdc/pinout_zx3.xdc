################################################################################
# zx3
# https://download.enclustra.com/public_files/SoC_Modules/Mars_ZX3/MA-ZX3-R7-1_User_Schematics_V1.pdf
################################################################################
# set_property PACKAGE_PIN P17 [get_ports          drs_wsrin_o]; # IO_B34_L20_P17_P
# set_property PACKAGE_PIN A21 [get_ports         drs_wsrout_i]; # IO_B35_L15_AD12_A21_P
set_property PACKAGE_PIN P18 [get_ports        drs_denable_o]; # IO_B34_L20_P18_N
set_property PACKAGE_PIN P16 [get_ports         drs_dwrite_o]; # IO_B34_L24_P16_P
set_property PACKAGE_PIN R16 [get_ports        drs_plllock_i]; # IO_B34_L24_R16_N
set_property PACKAGE_PIN P20 [get_ports           drs_dtap_i]; # IO_B34_L18_P20_P
set_property PACKAGE_PIN P21 [get_ports        drs_addr_o[3]]; # IO_B34_L18_P21_N
set_property PACKAGE_PIN N15 [get_ports        drs_addr_o[2]]; # IO_B34_L19_N15_P
set_property PACKAGE_PIN P15 [get_ports       adc_data_i[13]]; # IO_B34_L19_VREF_P15_N
set_property PACKAGE_PIN R20 [get_ports       adc_data_i[12]]; # IO_B34_L17_R20_P
set_property PACKAGE_PIN R21 [get_ports       adc_data_i[11]]; # IO_B34_L17_R21_N
set_property PACKAGE_PIN M21 [get_ports       adc_data_i[10]]; # IO_B34_L15_M21_P
set_property PACKAGE_PIN M22 [get_ports        adc_data_i[9]]; # IO_B34_L15_M22_N
set_property PACKAGE_PIN L21 [get_ports        adc_data_i[8]]; # IO_B34_L10_L21_P
set_property PACKAGE_PIN L22 [get_ports        adc_data_i[7]]; # IO_B34_L10_L22_N
set_property PACKAGE_PIN J21 [get_ports        adc_data_i[6]]; # IO_B34_L8_J21_P
set_property PACKAGE_PIN J22 [get_ports        adc_data_i[5]]; # IO_B34_L8_J22_N
set_property PACKAGE_PIN E19 [get_ports        adc_data_i[4]]; # IO_B35_L21_AD14_E19_P
set_property PACKAGE_PIN E20 [get_ports        adc_data_i[3]]; # IO_B35_L21_AD14_E20_N
set_property PACKAGE_PIN H22 [get_ports        adc_data_i[2]]; # IO_B35_L24_AD15_H22_P
set_property PACKAGE_PIN G22 [get_ports        adc_data_i[1]]; # IO_B35_L24_AD15_G22_N
set_property PACKAGE_PIN F21 [get_ports        adc_data_i[0]]; # IO_B35_L23_F21_P
set_property PACKAGE_PIN F22 [get_ports         drs_nreset_o]; # IO_B35_L23_F22_N
set_property PACKAGE_PIN E21 [get_ports        drs_addr_o[1]]; # IO_B35_L17_AD5_E21_P
set_property PACKAGE_PIN D21 [get_ports        drs_addr_o[0]]; # IO_B35_L17_AD5_D21_N
set_property PACKAGE_PIN D20 [get_ports        drs_rsrload_o]; # IO_B35_L14_SRCC_AD4_D20_P
set_property PACKAGE_PIN C20 [get_ports          drs_srclk_o]; # IO_B35_L14_SRCC_AD4_C20_N
set_property PACKAGE_PIN B21 [get_ports           drs_srin_o]; # IO_B35_L18_AD13_B21_P
set_property PACKAGE_PIN B22 [get_ports          drs_srout_i]; # IO_B35_L18_AD13_B22_N
set_property PACKAGE_PIN L18 [get_ports            clock_i_p]; # IO_B34_L12_MRCC_L18_P
set_property PACKAGE_PIN L19 [get_ports            clock_i_n]; # IO_B34_L12_MRCC_L19_N
set_property PACKAGE_PIN A18 [get_ports             gfp_sdat]; # IO_B35_L10_AD11_A18_P
set_property PACKAGE_PIN A19 [get_ports             gfp_sclk]; # IO_B35_L10_AD11_A19_N
set_property PACKAGE_PIN A16 [get_ports       mt_trigger_i_p]; # IO_B35_L9_AD3_A16_P
set_property PACKAGE_PIN A17 [get_ports       mt_trigger_i_n]; # IO_B35_L9_AD3_A17_N
set_property PACKAGE_PIN H15 [get_ports             emio_sda];
set_property PACKAGE_PIN R15 [get_ports             emio_scl];
set_property PACKAGE_PIN R19 [get_ports        ext_trigger_i];

set_property PACKAGE_PIN W18 [get_ports        loss_of_lock_i]; # IO_MIO51_B33_L13_W18

set_property PULLDOWN true [get_ports ext_trigger_i]

set_property PACKAGE_PIN H18  [get_ports led[0]]
set_property PACKAGE_PIN AA14 [get_ports led[1]]
set_property PACKAGE_PIN AA13 [get_ports led[2]]
set_property PACKAGE_PIN AB15 [get_ports led[3]]
