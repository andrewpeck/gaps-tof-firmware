import os
import sys
import subprocess

# Relative location of Vivado bitstreams
bit_dir = '../bin/'

bit_dir_exist = os.path.isdir(bit_dir)

if bit_dir_exist == False:
  print("[ERROR] (create_fpga_manager_bin.py): bin/ dir required!")
  print("[INFO] (create_fpga_manager_bin.py): bitsream created?")
  print("[INFO] (create_fpga_manager_bin.py): Abort.")
  sys.exit()

# Main
# Go through each folder and create .bin from .bit

bin_dir_list = os.listdir(bit_dir)
#print(bin_dir_lists)
