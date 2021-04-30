"""
Author: Sean Quinn (spq@ucla.edu)
client.py (c) UCLA 2021
Desc: Uses Vivado bootgen to create bin from bit
Created:  2021-04-30T17:24:11.188Z
Modified: 2021-04-30T17:27:30.553Z
"""
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

for i, folder in enumerate(bin_dir_list):
  # Get file list of each version controlled folder
  vcs_path = bit_dir + folder + '/'
  vcs_dir_list = os.listdir(vcs_path)
  # Filter bit files
  bit_files = [x for x in vcs_dir_list if '.bit' in x and '.bin' not in x]
  # Generate bin files
  for j, bit_file in enumerate(bit_files):
    # First create temp bif file
    bif_text = "all:\n{\n\n  %s\n\n}" %(vcs_path + bit_file)
    bif_fname = bit_file.replace(".bit",".bif")
    with open(vcs_path + bif_fname, "w") as fd:
      fd.write(bif_text)
    cmd = ["bootgen",
           "-image",
           vcs_path + bif_fname,
           "-arch",
           "zynq",
           "-w",
           "-process_bitstream",
           "bin"
          ]
    subprocess.run(cmd)
