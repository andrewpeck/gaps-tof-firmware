set PATH_REPO "[file normalize [file dirname [info script]]]/../pre-synthesis.tcl"

exec sed -i  "s/.*\\(--\\)-*\\(.*emio.*\\)/  \\2/" drs/src/ps_interface.vhd
exec sed -i  "s/.*\\(--\\)-*\\(.*emio.*\\)/  \\2/" drs/src/daq_board_top.vhd
