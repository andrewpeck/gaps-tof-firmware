source "[file normalize [file dirname [info script]]]/../pre-synthesis.tcl"

exec sed -i -e "s/--\\(emio.*\\)/--\\1/" drs/src/daq_board_top.vhd
exec sed -i -e "s/--\\(emio.*\\)/--\\1/" drs/src/ps_interface.vhd
