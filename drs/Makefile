.PHONY: run_daq_tb

run_daq_tb:  daq_tb
	./daq_tb

daq_tb: src/types_pkg.vhd src/daq.vhd sim/daq_tb.vhd src/crc32.vhd
	ghdl -a --std=08 --ieee=synopsys src/crc32.vhd src/types_pkg.vhd src/daq.vhd sim/daq_tb.vhd
	ghdl -e --std=08 --ieee=synopsys daq_tb

clean:
	rm -f *.o *.ghw *.cf daq_tb
