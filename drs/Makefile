SHELL := /bin/bash

.PHONY: check_output

DAQ_FILES=src/crc32.vhd src/types_pkg.vhd src/daq.vhd sim/daq_tb.vhd
ANALYZE=ghdl -a --std=08 --ieee=synopsys -Wunused --warn-runtime-error --warn-body --warn-parenthesis --warn-reserved
RUN=ghdl -r --std=08

all:
	make trigger_mux
	make check_output

check_output:  daq_packet.dat
	@python3 parse_daq.py
	make analyze

dumb_check:  daq_packet.txt
	@python3 dumb_parse_daq.py

daq_packet.dat:  daq_tb
	#cat example_packet.txt >> daq_packet.txt
	@python3 hex_to_bin.py

daq_tb: $(DAQ_FILES)
	@ghdl -a --std=08 --ieee=synopsys $(DAQ_FILES)
	@ghdl -r --std=08 --ieee=synopsys daq_tb --wave=daq_tb.ghw

dump: daq_packet.dat
	@od --width=2 -t x2 --endian big  daq_packet.dat

clean:
	rm -f *.o *.ghw *.cf daq_tb daq_packet.txt daq_packet.dat

trigger_mux:
	@ghdl -a --std=08 src/trigger_mux.vhd sim/trigger_mux_tb.vhd
	@ghdl -e --std=08 trigger_mux_tb
	@ghdl -r --std=08 trigger_mux_tb --wave=trigger_mux_tb.ghw

trigger_mux_questa:
	vcom -2008 src/trigger_mux.vhd sim/trigger_mux_tb.vhd
	vsim trigger_mux_tb

questa:
	vcom -2008 $(DAQ_FILES)
	vsim daq_tb

dtap:
	$(ANALYZE) src/dtap.vhd sim/dtap_tb.vhd
	$(RUN) dtap_tb

analyze:
	$(shell \
		FOLDER=software ; \
		if [ ! -d "$FOLDER" ] ; then \
				git clone https://gitlab.com/ucla-gaps-tof/software  ; \
		else \
				cd "$FOLDER" ; \
				git pull ; \
		fi \
	)
	cd software && git checkout data_format_updates && cd -
	python3 software/analysis/blob_to_packets.py daq_packet.dat
	python3 software/analysis/get_packet_data.py PACKETS_daq_packet/
