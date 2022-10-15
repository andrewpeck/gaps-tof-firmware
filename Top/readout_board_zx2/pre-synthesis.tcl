exec gawk -i inplace "!/.*IIC*./" drs/src/ps_interface.vhd
exec gawk -i inplace "!/.*emio*./" drs/src/daq_board_top.vhd
