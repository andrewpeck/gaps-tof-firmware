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


# ----------------------------------------------------------------------------------
# -- camera link 0 connector
# ----------------------------------------------------------------------------------


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


# ----------------------------------------------------------------------------------
# -- pmod I/O connector C
# ----------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------
# -- anios I/O connector A
# ----------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------
# -- pmod I/O connector B
# ----------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------
# -- I/O connector D
# ----------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------
# -- timing constraints
# ----------------------------------------------------------------------------------
# -- Available only on XC7Z020

#create_clock -name CLK33 -period 30.000 [get_ports CLK33]


# ----------------------------------------------------------------------------------------------------
# eof
# ----------------------------------------------------------------------------------------------------

