# -------------------------------------------------------------------------------------------------
# -- Project             : Mars ZX2 Reference Design
# -- File description    : Pin assignment and timing constraints file for Mars EB1
# -- File name           : MarsZX2_EB1.xdc
# -- Authors             : Gian Koeppel
# -------------------------------------------------------------------------------------------------
# -- Copyright (c) 2017 by Enclustra GmbH, Switzerland. All rights are reserved.
# -- Unauthorized duplication of this document, in whole or in part, by any means is prohibited
# -- without the prior written permission of Enclustra GmbH, Switzerland.
# --
# -- Although Enclustra GmbH believes that the information included in this publication is correct
# -- as of the date of publication, Enclustra GmbH reserves the right to make changes at any time
# -- without notice.
# --
# -- All information in this document may only be published by Enclustra GmbH, Switzerland.
# -------------------------------------------------------------------------------------------------
# -- Notes:
# -- The IO standards might need to be adapted to your design
# -------------------------------------------------------------------------------------------------
# -- File history:
# --
# -- Version | Date       | Author             | Remarks
# -- ----------------------------------------------------------------------------------------------
# -- 1.0     | 07.05.2015 | G. Koeppel         | First released version
# -- 2.0     | 20.10.2017 | D. Ungureanu       | Consistency checks
# --
# -------------------------------------------------------------------------------------------------

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]

# ----------------------------------------------------------------------------------
# Important! Do not remove this constraint!
# This property ensures that all unused pins are set to high impedance.
# If the constraint is removed, all unused pins have to be set to HiZ in the top level file.
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]
# ----------------------------------------------------------------------------------

set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]

# ----------------------------------------------------------------------------------
# -- Some I/Os are available only on XC7Z020
# -- Uncomment the constraints for these pins when you want to use them
# ----------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------
# -- I/Os connected in parallel with MIO pins, set to high impedance if not used
# -- Available only on XC7Z020
# ----------------------------------------------------------------------------------

# set_property PACKAGE_PIN V5 [get_ports ETH_Link]
# set_property IOSTANDARD LVCMOS25 [get_ports ETH_Link]
# 
# set_property PACKAGE_PIN Y7 [get_ports CLK33]
# set_property IOSTANDARD LVCMOS25 [get_ports CLK33]
# 
# set_property PACKAGE_PIN W10 [get_ports MIO40]
# set_property IOSTANDARD LVCMOS25 [get_ports MIO40]
# 
# set_property PACKAGE_PIN W9 [get_ports MIO41]
# set_property IOSTANDARD LVCMOS25 [get_ports MIO41]
# 
# set_property PACKAGE_PIN W11 [get_ports MIO42]
# set_property IOSTANDARD LVCMOS25 [get_ports MIO42]
# 
# set_property PACKAGE_PIN Y11 [get_ports MIO43]
# set_property IOSTANDARD LVCMOS25 [get_ports MIO43]
# 
# set_property PACKAGE_PIN Y9 [get_ports MIO44]
# set_property IOSTANDARD LVCMOS25 [get_ports MIO44]
# 
# set_property PACKAGE_PIN Y8 [get_ports MIO45]
# set_property IOSTANDARD LVCMOS25 [get_ports MIO45]

# ----------------------------------------------------------------------------------
# -- shared with MIO UART 
# ----------------------------------------------------------------------------------

# set_property PACKAGE_PIN T5 [get_ports MIO46]
# set_property IOSTANDARD LVCMOS25 [get_ports MIO46]
# 
# set_property PACKAGE_PIN U5 [get_ports MIO47]
# set_property IOSTANDARD LVCMOS25 [get_ports MIO47]

#MIO 48-51 used for the system controller/camera link

# ----------------------------------------------------------------------------------
# -- led
# ----------------------------------------------------------------------------------

set_property PACKAGE_PIN R19 [get_ports {Led_N[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Led_N[0]}]

set_property PACKAGE_PIN T19 [get_ports {Led_N[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Led_N[1]}]

set_property PACKAGE_PIN G14 [get_ports {Led_N[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Led_N[2]}]

set_property PACKAGE_PIN J15 [get_ports {Led_N[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Led_N[3]}]


# ----------------------------------------------------------------------------------
# -- i2-port
# ----------------------------------------------------------------------------------
# -- Available only on XC7Z020

# set_property PACKAGE_PIN W8 [get_ports I2C0_SDA]
# set_property IOSTANDARD LVCMOS25 [get_ports I2C0_SDA]
# 
# set_property PACKAGE_PIN V8 [get_ports I2C0_SCL]
# set_property IOSTANDARD LVCMOS25 [get_ports I2C0_SCL]
# 
# set_property PACKAGE_PIN Y6 [get_ports I2C0_INT_N]
# set_property IOSTANDARD LVCMOS25 [get_ports I2C0_INT_N]


# ----------------------------------------------------------------------------------
# Mars EB1 specific signals
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- hdmi connector
# ----------------------------------------------------------------------------------

set_property PACKAGE_PIN N20 [get_ports HDMI_CLK_P]
set_property IOSTANDARD LVCMOS25 [get_ports HDMI_CLK_P]
set_property PACKAGE_PIN P20 [get_ports HDMI_CLK_N]
set_property IOSTANDARD LVCMOS25 [get_ports HDMI_CLK_N]
set_property PACKAGE_PIN V15 [get_ports HDMI_D2_P]
set_property IOSTANDARD LVCMOS25 [get_ports HDMI_D2_P]
set_property PACKAGE_PIN W15 [get_ports HDMI_D2_N]
set_property IOSTANDARD LVCMOS25 [get_ports HDMI_D2_N]
set_property PACKAGE_PIN Y16 [get_ports HDMI_D1_P]
set_property IOSTANDARD LVCMOS25 [get_ports HDMI_D1_P]
set_property PACKAGE_PIN Y17 [get_ports HDMI_D1_N]
set_property IOSTANDARD LVCMOS25 [get_ports HDMI_D1_N]
set_property PACKAGE_PIN Y18 [get_ports HDMI_D0_P]
set_property IOSTANDARD LVCMOS25 [get_ports HDMI_D0_P]
set_property PACKAGE_PIN Y19 [get_ports HDMI_D0_N]
set_property IOSTANDARD LVCMOS25 [get_ports HDMI_D0_N]
set_property PACKAGE_PIN W18 [get_ports HDMI_HPD]
set_property IOSTANDARD LVCMOS25 [get_ports HDMI_HPD]
set_property PACKAGE_PIN W19 [get_ports HDMI_CEC]
set_property IOSTANDARD LVCMOS25 [get_ports HDMI_CEC]

# ----------------------------------------------------------------------------------
# -- camera link 0 connector
# ----------------------------------------------------------------------------------

set_property PACKAGE_PIN M20 [get_ports CAM0_CC1_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_CC1_N]
set_property PACKAGE_PIN M19 [get_ports CAM0_CC1_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_CC1_P]
set_property PACKAGE_PIN N16 [get_ports CAM0_CC2_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_CC2_N]
set_property PACKAGE_PIN N15 [get_ports CAM0_CC2_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_CC2_P]
set_property PACKAGE_PIN H20 [get_ports CAM0_SERTC_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_SERTC_N]
set_property PACKAGE_PIN J20 [get_ports CAM0_SERTC_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_SERTC_P]
set_property PACKAGE_PIN M18 [get_ports CAM0_SERTFG_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_SERTFG_N]
set_property PACKAGE_PIN M17 [get_ports CAM0_SERTFG_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_SERTFG_P]
set_property PACKAGE_PIN G15 [get_ports CAM0_X0_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_X0_N]
set_property PACKAGE_PIN H15 [get_ports CAM0_X0_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_X0_P]
set_property PACKAGE_PIN J14 [get_ports CAM0_X1_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_X1_N]
set_property PACKAGE_PIN K14 [get_ports CAM0_X1_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_X1_P]
set_property PACKAGE_PIN L15 [get_ports CAM0_X2_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_X2_N]
set_property PACKAGE_PIN L14 [get_ports CAM0_X2_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_X2_P]
set_property PACKAGE_PIN M15 [get_ports CAM0_X3_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_X3_N]
set_property PACKAGE_PIN M14 [get_ports CAM0_X3_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_X3_P]
set_property PACKAGE_PIN K18 [get_ports CAM0_XCLK_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_XCLK_N]
set_property PACKAGE_PIN K17 [get_ports CAM0_XCLK_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM0_XCLK_P]

# CC3/CC4 shared with system controller SIO pins (assembly option)
# ----------------------------------------------------------------------------------
# -- I/Os connected in parallel with MIO pins, set to high impedance if not used
# -- Available only on XC7Z020
# ----------------------------------------------------------------------------------

# set_property PACKAGE_PIN U7 [get_ports SIO0_SCINT_P_n]
# set_property IOSTANDARD LVCMOS25 [get_ports SIO0_SCINT_P_n]
# set_property PACKAGE_PIN V7 [get_ports SIO1_CPULED_N_n]
# set_property IOSTANDARD LVCMOS25 [get_ports SIO1_CPULED_N_n]
# set_property PACKAGE_PIN T9 [get_ports SIO2_SDCD_P_n]
# set_property IOSTANDARD LVCMOS25 [get_ports SIO2_SDCD_P_n]
# set_property PACKAGE_PIN U10 [get_ports SIO3_SDIOSEL_N_n]
# set_property IOSTANDARD LVCMOS25 [get_ports SIO3_SDIOSEL_N_n]

# ----------------------------------------------------------------------------------
# -- camera link 1 connector
# ----------------------------------------------------------------------------------

set_property PACKAGE_PIN G20 [get_ports CAM1_SERTC_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_SERTC_N]
set_property PACKAGE_PIN G19 [get_ports CAM1_SERTC_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_SERTC_P]
set_property PACKAGE_PIN J16 [get_ports CAM1_SERTFG_Z0_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_SERTFG_Z0_N]
set_property PACKAGE_PIN K16 [get_ports CAM1_SERTFG_Z0_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_SERTFG_Z0_P]
set_property PACKAGE_PIN D18 [get_ports CAM1_XY0_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_XY0_N]
set_property PACKAGE_PIN E17 [get_ports CAM1_XY0_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_XY0_P]
set_property PACKAGE_PIN E19 [get_ports CAM1_XY1_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_XY1_N]
set_property PACKAGE_PIN E18 [get_ports CAM1_XY1_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_XY1_P]
set_property PACKAGE_PIN F17 [get_ports CAM1_XY2_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_XY2_N]
set_property PACKAGE_PIN F16 [get_ports CAM1_XY2_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_XY2_P]
set_property PACKAGE_PIN G18 [get_ports CAM1_XY3_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_XY3_N]
set_property PACKAGE_PIN G17 [get_ports CAM1_XY3_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_XY3_P]
set_property PACKAGE_PIN L17 [get_ports CAM1_XYCLK_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_XYCLK_N]
set_property PACKAGE_PIN L16 [get_ports CAM1_XYCLK_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_XYCLK_P]
set_property PACKAGE_PIN H18 [get_ports CAM1_Z1N_CC1_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_Z1N_CC1_N]
set_property PACKAGE_PIN J18 [get_ports CAM1_Z1P_CC1_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_Z1P_CC1_P]
set_property PACKAGE_PIN J19 [get_ports CAM1_Z2P_CC2_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_Z2P_CC2_N]
set_property PACKAGE_PIN K19 [get_ports CAM1_Z2N_CC2_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_Z2N_CC2_P]
set_property PACKAGE_PIN L20 [get_ports CAM1_Z3P_CC4_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_Z3P_CC4_N]
set_property PACKAGE_PIN L19 [get_ports CAM1_Z3N_CC4_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_Z3N_CC4_P]
set_property PACKAGE_PIN H17 [get_ports CAM1_ZCLK_CC3_N]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_ZCLK_CC3_N]
set_property PACKAGE_PIN H16 [get_ports CAM1_ZCLK_CC3_P]
set_property IOSTANDARD LVCMOS25 [get_ports CAM1_ZCLK_CC3_P]

# ----------------------------------------------------------------------------------
# -- pmod I/O connector C
# ----------------------------------------------------------------------------------

set_property PACKAGE_PIN F19 [get_ports IOC_D0_SC0_BTN0_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOC_D0_SC0_BTN0_N]
set_property PACKAGE_PIN F20 [get_ports IOC_D1_SC1_BTN1_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOC_D1_SC1_BTN1_N]
set_property PACKAGE_PIN D19 [get_ports IOC_D2_SC2]
set_property IOSTANDARD LVCMOS25 [get_ports IOC_D2_SC2]
set_property PACKAGE_PIN D20 [get_ports IOC_D3_SC3]
set_property IOSTANDARD LVCMOS25 [get_ports IOC_D3_SC3]
set_property PACKAGE_PIN C20 [get_ports IOC_D4_SC4]
set_property IOSTANDARD LVCMOS25 [get_ports IOC_D4_SC4]
set_property PACKAGE_PIN B20 [get_ports IOC_D5_SC5]
set_property IOSTANDARD LVCMOS25 [get_ports IOC_D5_SC5]
set_property PACKAGE_PIN B19 [get_ports IOC_D6_SC6]
set_property IOSTANDARD LVCMOS25 [get_ports IOC_D6_SC6]
set_property PACKAGE_PIN A20 [get_ports IOC_D7_SC7]
set_property IOSTANDARD LVCMOS25 [get_ports IOC_D7_SC7]

# ----------------------------------------------------------------------------------
# -- anios I/O connector A
# ----------------------------------------------------------------------------------

set_property PACKAGE_PIN P19 [get_ports IOA_CLK_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_CLK_N]
set_property PACKAGE_PIN N18 [get_ports IOA_CLK_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_CLK_P]
set_property PACKAGE_PIN W14 [get_ports IOA_D0_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D0_P]
set_property PACKAGE_PIN Y14 [get_ports IOA_D1_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D1_N]
set_property PACKAGE_PIN P14 [get_ports IOA_D2_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D2_P]
set_property PACKAGE_PIN R14 [get_ports IOA_D3_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D3_N]
set_property PACKAGE_PIN T14 [get_ports IOA_D4_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D4_P]
set_property PACKAGE_PIN T15 [get_ports IOA_D5_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D5_N]
set_property PACKAGE_PIN T16 [get_ports IOA_D6_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D6_P]
set_property PACKAGE_PIN U17 [get_ports IOA_D7_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D7_N]
set_property PACKAGE_PIN P15 [get_ports IOA_D8_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D8_P]
set_property PACKAGE_PIN P16 [get_ports IOA_D9_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D9_N]
set_property PACKAGE_PIN N17 [get_ports IOA_D10_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D10_P]
set_property PACKAGE_PIN P18 [get_ports IOA_D11_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D11_N]
set_property PACKAGE_PIN V20 [get_ports IOA_D12_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D12_P]
set_property PACKAGE_PIN W20 [get_ports IOA_D13_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D13_N]
set_property PACKAGE_PIN T20 [get_ports IOA_D14_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D14_P]
set_property PACKAGE_PIN U20 [get_ports IOA_D15_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D15_N]
set_property PACKAGE_PIN T11 [get_ports IOA_D16_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D16_P]
set_property PACKAGE_PIN T10 [get_ports IOA_D17_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D17_N]
set_property PACKAGE_PIN V12 [get_ports IOA_D18_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D18_P]
set_property PACKAGE_PIN W13 [get_ports IOA_D19_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D19_N]
set_property PACKAGE_PIN V16 [get_ports IOA_D20_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D20_P]
set_property PACKAGE_PIN W16 [get_ports IOA_D21_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D21_N]
set_property PACKAGE_PIN R16 [get_ports IOA_D22_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D22_P]
set_property PACKAGE_PIN R17 [get_ports IOA_D23_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOA_D23_N]

# ----------------------------------------------------------------------------------
# -- pmod I/O connector B
# ----------------------------------------------------------------------------------

set_property PACKAGE_PIN T17 [get_ports IOB_D0_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOB_D0_P]
set_property PACKAGE_PIN R18 [get_ports IOB_D1_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOB_D1_N]
set_property PACKAGE_PIN V17 [get_ports IOB_D2_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOB_D2_P]
set_property PACKAGE_PIN V18 [get_ports IOB_D3_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOB_D3_N]
set_property PACKAGE_PIN T12 [get_ports IOB_D4_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOB_D4_P]
set_property PACKAGE_PIN U12 [get_ports IOB_D5_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOB_D5_N]
set_property PACKAGE_PIN U13 [get_ports IOB_D6_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOB_D6_P]
set_property PACKAGE_PIN V13 [get_ports IOB_D7_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOB_D7_N]

# ----------------------------------------------------------------------------------
# -- I/O connector D
# ----------------------------------------------------------------------------------

set_property PACKAGE_PIN U18 [get_ports IOD_D0_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOD_D0_P]
set_property PACKAGE_PIN U19 [get_ports IOD_D1_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOD_D1_N]
set_property PACKAGE_PIN U14 [get_ports IOD_D2_P]
set_property IOSTANDARD LVCMOS25 [get_ports IOD_D2_P]
set_property PACKAGE_PIN U15 [get_ports IOD_D3_N]
set_property IOSTANDARD LVCMOS25 [get_ports IOD_D3_N]

# ----------------------------------------------------------------------------------
# -- timing constraints
# ----------------------------------------------------------------------------------
# -- Available only on XC7Z020

#create_clock -name CLK33 -period 30.000 [get_ports CLK33]


# ----------------------------------------------------------------------------------------------------
# eof
# ----------------------------------------------------------------------------------------------------
