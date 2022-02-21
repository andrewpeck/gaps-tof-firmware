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
