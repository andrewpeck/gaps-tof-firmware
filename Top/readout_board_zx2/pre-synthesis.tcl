source "[file normalize [file dirname [info script]]]/../pre-synthesis.tcl"

exec sed -i "s/.*emio*./--&/" drs/src/ps_interface.vhd
exec sed -i "s/.*emio*./--&/" drs/src/daq_board_top.vhd
