################################################################################
# Config
################################################################################

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

################################################################################
# Input Clocks
################################################################################

create_clock -period 10.0 -name sys_clk [get_ports sys_clk_i]

create_clock -period 50.0 -name clock_i_20 [get_ports clk_p]

create_clock -period 8.0 -name rgmii_rx_clk [get_ports rgmii_rx_clk]

create_clock -period 50.000 -name {fb_clk_p[0]} -waveform {0.000 25.000} [get_ports {fb_clk_p[0]}]
create_clock -period 50.000 -name {fb_clk_p[1]} -waveform {0.000 25.000} [get_ports {fb_clk_p[1]}]
create_clock -period 50.000 -name {fb_clk_p[2]} -waveform {0.000 25.000} [get_ports {fb_clk_p[2]}]
create_clock -period 50.000 -name {fb_clk_p[3]} -waveform {0.000 25.000} [get_ports {fb_clk_p[3]}]
create_clock -period 50.000 -name {fb_clk_p[4]} -waveform {0.000 25.000} [get_ports {fb_clk_p[4]}]

# these are not on dedicated routes
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets fb_clk_i_*]

################################################################################
# CDC exemptions
################################################################################

set_max_delay -datapath_only 5.0 \
    -from [get_pins eth_infra_inst/eth_mac_1g_rgmii_inst/rx_fifo/fifo_inst/s_rst_sync1_reg_reg/C] \
    -to [get_pins eth_infra_inst/eth_mac_1g_rgmii_inst/rx_fifo/fifo_inst/s_rst_sync2_reg_reg/D]

set_max_delay -datapath_only 5.0 \
    -from [get_pins eth_infra_inst/eth_mac_1g_rgmii_inst/tx_fifo/fifo_inst/s_rst_sync1_reg_reg/C] \
    -to [get_pins eth_infra_inst/eth_mac_1g_rgmii_inst/tx_fifo/fifo_inst/s_rst_sync2_reg_reg/D]

set_max_delay -datapath_only 5.0 \
    -from [get_pins eth_infra_inst/eth_mac_1g_rgmii_inst/rx_fifo/fifo_inst/s_rst_sync1_reg_reg/C] \
    -to [get_pins eth_infra_inst/eth_mac_1g_rgmii_inst/rx_fifo/fifo_inst/s_rst_sync2_reg_reg/D]

set_max_delay -datapath_only 5.0 \
    -from [get_pins {eth_infra_inst/eth_mac_1g_rgmii_inst/tx_fifo/fifo_inst/rd_ptr_gray_reg_reg[*]/C}] \
    -to [get_pins {eth_infra_inst/eth_mac_1g_rgmii_inst/tx_fifo/fifo_inst/rd_ptr_gray_sync1_reg_reg[*]/D}]

set_max_delay -datapath_only 5.0 \
    -from [get_pins {eth_infra_inst/eth_mac_1g_rgmii_inst/tx_fifo/fifo_inst/wr_ptr_sync_gray_reg_reg[*]/C}] \
    -to [get_pins {eth_infra_inst/eth_mac_1g_rgmii_inst/tx_fifo/fifo_inst/wr_ptr_gray_sync1_reg_reg[*]/D}]

set_max_delay -datapath_only 5.0 \
  -from [get_pins eth_infra_inst/eth_mac_1g_rgmii_inst/tx_fifo/fifo_inst/wr_ptr_update_reg_reg/C] \
  -to [get_pins eth_infra_inst/eth_mac_1g_rgmii_inst/tx_fifo/fifo_inst/wr_ptr_update_sync1_reg_reg/D]

set_max_delay -datapath_only 5.0 \
    -from [get_clocks rgmii_rx_clk] \
    -to [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT0]]

set_max_delay -datapath_only 5.0 \
    -from [get_clocks -of_objects [get_pins clocking/clocking/inst/mmcm_adv_inst/CLKOUT0]] \
    -to [get_clocks rgmii_rx_clk]

set_max_delay -datapath_only 5.0 \
    -from [get_pins eth_infra_inst/eth_mac_1g_rgmii_inst/rx_fifo/fifo_inst/s_rst_sync1_reg_reg/C] \
    -to [get_pins eth_infra_inst/eth_mac_1g_rgmii_inst/tx_fifo/fifo_inst/m_rst_sync2_reg_reg/D]

set_max_delay -datapath_only 5.0 \
    -from [get_pins {reset_ff_reg[0]/C}] \
    -to [get_pins eth_infra_inst/gtx_rst_r0_reg/D]

################################################################################
#
################################################################################

set_property -dict { PACKAGE_PIN "K21" IOSTANDARD LVCMOS33} [get_ports {rst_button_i}]; # IO_0_14 Sch = RSTPIN
set_property -dict { PACKAGE_PIN "F22" IOSTANDARD LVCMOS33} [get_ports {sys_clk_i}]; # IO_L12P_T1_MRCC_14 Sch = CLK1

set_property PACKAGE_PIN "Y6" [get_ports {sump_o}]; # choose an unused pin
set_property IOSTANDARD LVCMOS15 [get_ports sump_o]

set_property IOSTANDARD LVDS_25 [get_ports fb_clk_*]
set_property IOSTANDARD LVDS_25 [get_ports clk_*]

# mode
set_property PULLDOWN true [get_ports rgmii_rxd[0]]
set_property PULLDOWN true [get_ports rgmii_rxd[1]]
set_property PULLUP true [get_ports rgmii_rxd[2]]
set_property PULLUP true [get_ports rgmii_rxd[3]]

# clk125 en
set_property PULLUP true [get_ports rgmii_rx_ctl]

# reset
set_property PULLDOWN true [get_ports rgmii_reset_n]

# led mode
set_property PULLDOWN true [get_ports rgmii_clk125]

set_property IOSTANDARD LVCMOS25 [get_ports *rgmii*];

set_property SLEW FAST [get_ports rgmii_tx*]
set_property DRIVE 16 [get_ports rgmii_tx*]

set_property PULLUP true [get_ports rgmii_mdc]
set_property PULLUP true [get_ports rgmii_mdio]

################################################################################
# RGMII Constraints
# https://support.xilinx.com/s/question/0D52E00006hpKWvSAM/timing-constraints-for-rgmii?language=en_US
################################################################################

# receiver

set rx_clk [get_clocks rgmii_rx_clk]

set rgmiirx_rxc_period      8.000;
set rgmiirx_dv_bre          1.200;
set rgmiirx_dv_are          1.200;
set rgmiirx_dv_bfe          1.200;
set rgmiirx_dv_afe          1.200;
set input_ports             [list rgmii_rx_ctl {rgmii_rxd[0]} {rgmii_rxd[1]} {rgmii_rxd[2]} {rgmii_rxd[3]}];

set_input_delay -clock $rx_clk -max [expr $rgmiirx_rxc_period/2 - $rgmiirx_dv_bfe] [get_ports $input_ports] -add_delay;
set_input_delay -clock $rx_clk -min $rgmiirx_dv_are [get_ports $input_ports] -add_delay;
set_input_delay -clock $rx_clk -max [expr $rgmiirx_rxc_period/2 - $rgmiirx_dv_bre] [get_ports $input_ports] -clock_fall -add_delay;
set_input_delay -clock $rx_clk -min $rgmiirx_dv_afe [get_ports $input_ports] -clock_fall -add_delay;

#  Double Data Rate Source Synchronous Outputs
#
#  Source synchronous output interfaces can be constrained either by the max data skew
#  relative to the generated clock or by the destination device setup/hold requirements.
#
#  Setup/Hold Case:
#  Setup and hold requirements for the destination device and board trace delays are known.
#
# forwarded                        _________________________________
# clock                 __________|                                 |______________
#                                 |                                 |
#                           tsu_r |  thd_r                    tsu_f | thd_f
#                         <------>|<------->                <------>|<----->
#                         ________|_________                ________|_______
# data @ destination   XXX__________________XXXXXXXXXXXXXXXX________________XXXXX
#
# Example of creating generated clock at clock output port
# create_generated_clock -name <gen_clock_name> -multiply_by 1 -source [get_pins <source_pin>] [get_ports <output_clock_port>]
# gen_clock_name is the name of forwarded clock here. It should be used below for defining "fwclk".


# transmitter
create_generated_clock -name rgmii_tx_clk -multiply_by 1 \
    -source [get_pins eth_infra_inst/eth_mac_1g_rgmii_inst/rgmii_phy_if_inst/clk_oddr_inst/oddr[0].oddr_inst/C] [get_ports rgmii_tx_clk]

set fwclk        rgmii_tx_clk;     # forwarded clock name (generated using create_generated_clock at output clock port)
set tsu_r        1.000;            # destination device setup time requirement for rising edge
set thd_r        0.800;            # destination device hold time requirement for rising edge
set tsu_f        1.000;            # destination device setup time requirement for falling edge
set thd_f        0.800;            # destination device hold time requirement for falling edge
set trce_dly_max 0.000;            # maximum board trace delay
set trce_dly_min 0.000;            # minimum board trace delay
set output_ports [list rgmii_tx_ctl {rgmii_txd[0]} {rgmii_txd[1]} {rgmii_txd[2]} {rgmii_txd[3]}];   # list of output ports

# Output Delay Constraints
set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu_r] [get_ports $output_ports];
set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd_r] [get_ports $output_ports];
set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu_f] [get_ports $output_ports] -clock_fall -add_delay;
set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd_f] [get_ports $output_ports] -clock_fall -add_delay;

# these are assigned by the loop below, since different banks operate at
# different voltage standards
#
# set_property IOSTANDARD LVDS_25 [get_ports lt_data_i*]
# set_property IOSTANDARD LVCMOS25 [get_ports rb_data_o*]

set_property SLEW SLOW [get_ports hk_clk]
set_property SLEW SLOW [get_ports hk_cs_n]
set_property SLEW SLOW [get_ports hk_dout]

set_property DRIVE 4 [get_ports hk_clk]
set_property DRIVE 4 [get_ports hk_dout]
set_property DRIVE 4 [get_ports hk_cs_n]

set_property SLEW SLOW [get_ports rb_data_o*]
set_property DRIVE 4 [get_ports rb_data_o*]

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
