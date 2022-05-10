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
set_property IOSTANDARD LVCMOS15 [get_ports sump_o]

set_property IOSTANDARD LVDS_25 [get_ports fb_clk_*]
set_property IOSTANDARD LVDS_25 [get_ports clk_*]

# set_property IOSTANDARD          [get_ports sda]
# set_property IOSTANDARD          [get_ports scl]

set_property -dict {IOSTANDARD LVCMOS25} \
    [get_ports *rgmii*];

# these are assigned by the loop below, since different banks operate at
# different voltage standards
#
# set_property IOSTANDARD LVDS_25 [get_ports lt_data_i*]
# set_property IOSTANDARD LVCMOS25 [get_ports rb_data_o*]

set_property IOSTANDARD LVCMOS15 [get_ports lvs_sync[*]]
set_property IOSTANDARD LVCMOS15 [get_ports lvs_sync_ccb]
set_property IOSTANDARD LVCMOS15 [get_ports dsi_on]
set_property IOSTANDARD LVCMOS15 [get_ports clk_src_sel]

set_property IOSTANDARD LVCMOS33 [get_ports hk_cs_n*]
set_property IOSTANDARD LVCMOS33 [get_ports hk_clk]
set_property IOSTANDARD LVCMOS33 [get_ports hk_dout]
set_property IOSTANDARD LVCMOS33 [get_ports hk_din]

set_property IOSTANDARD LVCMOS15 [get_ports ext_io*]
set_property IOSTANDARD LVCMOS15 [get_ports ext_out*]
set_property IOSTANDARD LVCMOS15 [get_ports ext_in*]

# | Bank | Type | VCCO      |     #Diff | #SE | #If all SE |
# |------+------+-----------+-----------+-----+------------|
# |   12 | HR   | ADJ=+2.5V |        24 |   2 |         50 |
# |   14 | HR   | +3.3V     |         0 |  38 |         38 |
# |   15 | HR   | ADJ=+2.5V | 16 or 24* |   2 |  34 or 50* |
# |   16 | HR   | ADJ=+2.5V |        24 |   2 |         50 |
# |   32 | HP   | ADJ=+1.8V |        24 |   2 |         50 |
# |   33 | HP   | +1.5V     |        17 |   2 |         36 |

# Bank 34 --> 1.5V
# Bank 33 --> 1.5V
# Bank 32 --> VADJ
# Bank 16 --> VADJ
# Bank 15 --> VADJ
# Bank 14 --> VCC3V3
# Bank 13 --> VCC3V3
# Bank 12 --> VADJ
# Bank 0  --> VCC3V3

set bank_voltages [dict create \
                       34 1.5 \
                       33 1.5 \
                       32 1.8 \
                       16 2.5 \
                       15 2.5 \
                       14 3.3 \
                       13 3.3 \
                       12 2.5]

set ok_standards [dict create\
                      1.5 "LVCMOS15" \
                      1.8 "LVCMOS18 LVDS" \
                      2.5 "LVCMOS25 LVDS_25" \
                      3.3 "LVCMOS33"]

dict for {bank voltage} $bank_voltages {
    set ios [get_ports -quiet -of_objects [get_iobanks $bank]]
    foreach io $ios {

        # differential ports
        if {[lsearch $io "lt_data_i*"]>=0} {
            if {$voltage == 2.5} {
                set_property IOSTANDARD LVDS_25 [get_ports $io]
            } elseif {$voltage == 1.8} {
                set_property IOSTANDARD LVDS [get_ports $io]
            } else {
                error "Invalid bank voltage for $io"
            }
        }

        if {[lsearch $io "rb_data_o*"]>=0} {
            # interfaces with DS90LV031ATMTC
            # input voltage high = 2.0V, low=0.8V
            if {$voltage == 3.3} {
                set_property IOSTANDARD LVCMOS33 [get_ports $io]
                puts "set_property IOSTANDARD LVCMOS33 [get_ports $io]"
            } elseif {$voltage == 2.5} {
                set_property IOSTANDARD LVCMOS25 [get_ports $io]
            } else {
                error "Invalid bank voltage for $io"
            }
        }
    }
}

set err 0
dict for {bank voltage} $bank_voltages {
    set ios [get_ports -quiet -of_objects [get_iobanks $bank]]
    # puts "Bank $bank VCCO=$voltage"
    # puts "  > $ios"
    foreach io $ios {
        set ok_stds [dict get $ok_standards $voltage]
        set iostd [get_property IOSTANDARD [get_ports $io]]
        if {[lsearch $ok_stds $iostd] < 0} {
            puts " > $io at invalid voltage. VCCO=$voltage, IOSTANDARD=$iostd (valid stds = $ok_stds)"
            # puts " > $ok_stds"
            set err [expr 1 + $err]
        }
    }
}

if {$err > 0} {
    error "Error found in IO assignment"
}

#set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 34]];
#set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];
