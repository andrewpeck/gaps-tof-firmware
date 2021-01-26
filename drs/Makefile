.PHONY: check_output

check_output:  daq_packet.dat
	@python3 parse_daq.py

dumb_check:  daq_packet.txt
	@python3 dumb_parse_daq.py

daq_packet.dat:  daq_tb
	@python3 hex_to_bin.py

daq_tb: src/types_pkg.vhd src/daq.vhd sim/daq_tb.vhd src/crc32.vhd
	ghdl -a --std=08 --ieee=synopsys src/crc32.vhd src/types_pkg.vhd src/daq.vhd sim/daq_tb.vhd
	ghdl -r --std=08 --ieee=synopsys daq_tb

dump: daq_packet.dat
	@od --width=2 -t x2 --endian big  daq_packet.dat

clean:
	rm -f *.o *.ghw *.cf daq_tb daq_packet.txt daq_packet.dat
