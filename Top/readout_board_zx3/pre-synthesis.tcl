set_msg_config -id {Synth 8-6859} -new_severity {ERROR}

exec sed -i  "s/.*\\(--\\)-*\\(.*emio.*\\)/  \\2/" drs/src/ps_interface.vhd
exec sed -i  "s/.*\\(--\\)-*\\(.*emio.*\\)/  \\2/" drs/src/daq_board_top.vhd
