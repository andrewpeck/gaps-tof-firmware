#!/usr/bin/env python3
import binascii

with open("daq_packet.txt", "r") as daq_file:
    lines = daq_file.readlines()

with open ("daq_packet.dat", "wb+") as bin_file:
    for line in lines:
        bindata = int(line,16).to_bytes(2, byteorder='little')
        bin_file.write(bindata)
