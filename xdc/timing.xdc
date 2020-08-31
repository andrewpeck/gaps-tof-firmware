create_clock -period 30.0 -name clock33   [get_ports clock_i_p]

# 33MHz inputs
set_input_delay -clock [get_clocks clock33] 5.000 [get_ports -filter { NAME =~  "*adc*" && DIRECTION == "IN" }]
set_input_delay -clock [get_clocks clock33] 5.000 [get_ports -filter { NAME =~  "*srout*" && DIRECTION == "IN" }]

# 33MHz outputs

# DWRITE Special Output

set_input_delay -clock [get_clocks clock33] -min 5.000 [get_ports trigger_i_n]
set_input_delay -clock [get_clocks clock33] -max 7.000 [get_ports trigger_i_n]

set_input_delay -clock [get_clocks clock33] -min 5.000 [get_ports trigger_i_p]
set_input_delay -clock [get_clocks clock33] -max 7.000 [get_ports trigger_i_p]


set_output_delay -clock [get_clocks clock33] -min 4.000 [get_ports {drs_addr_o[*]}]
set_output_delay -clock [get_clocks clock33] -max 5.000 [get_ports {drs_addr_o[*]}]

set_output_delay -clock [get_clocks clock33] -min 4.000 [get_ports drs_denable_o]
set_output_delay -clock [get_clocks clock33] -max 5.000 [get_ports drs_denable_o]

set_output_delay -clock [get_clocks clock33] -min 4.000 [get_ports drs_dwrite_o]
set_output_delay -clock [get_clocks clock33] -max 5.000 [get_ports drs_dwrite_o]

set_output_delay -clock [get_clocks clock33] -min 4.000 [get_ports drs_rsrload_o]
set_output_delay -clock [get_clocks clock33] -max 5.000 [get_ports drs_rsrload_o]

set_output_delay -clock [get_clocks clock33] -min 4.000 [get_ports drs_srin_o]
set_output_delay -clock [get_clocks clock33] -max 5.000 [get_ports drs_srin_o]
