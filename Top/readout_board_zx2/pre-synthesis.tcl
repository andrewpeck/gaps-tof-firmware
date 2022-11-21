set_msg_config -id {Synth 8-6859} -new_severity {ERROR}

exec sed -i "s/.*emio*./--&/" drs/src/ps_interface.vhd
exec sed -i "s/.*emio*./--&/" drs/src/daq_board_top.vhd
