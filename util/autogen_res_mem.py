"""
Author: Sean Quinn (spq@ucla.edu)
autogen_res_mem.py (c) UCLA 2021
Desc: Autopopulate start address in dma_controller.vhd from device tree
Created:  2021-06-15T23:13:01.077Z
Modified: 2021-06-17T21:37:31.048Z
"""

import re
import sys

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def format_hex(x):
  # Return VHDL compatible hex strings
  # Input must be string, 0xaaaa format
  try:
    int_val = int(x,16)
  except:
    print(f"autogen_res_mem.py [{bcolors.FAIL}ERROR{bcolors.ENDC}]: could not convert hex string to int")
    sys.exit()
  out_str = f"0x{int_val:08x}"
  return out_str

def get_rambuff_addr_size(x):
  # Use regex to find the address, and size of reserved memory
  # returns addr, size
  pat = re.compile(r"rambuffer@\d+\s+\{\n\t+reg\s+=\s+<[\w\d\s]+>")
  matches = pat.findall(x)

  hex_addr_pat = re.compile(r"(0x\d{1,8})")

  # Check something was found
  if len(matches) == 0:
    print(f"autogen_res_mem.py [{bcolors.FAIL}ERROR{bcolors.ENDC}]: could not find reserved memory node!")
    return -1
  else:
    if len(matches) > 1:
      print (f"autogen_res_mem.py [{bcolors.WARNING}WARN{bcolors.ENDC}]: found multiple reserved regions, using first instance")
    reg_str = matches[0]
    addr, size = hex_addr_pat.findall(reg_str)
    addr_vhdl_str = format_hex(addr)
    size_vhdl_str = format_hex(size)
    return addr_vhdl_str, size_vhdl_str


# path to dts file
sys_usr_file = "plnx/ucla/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi"

with open(sys_usr_file, "r") as f:
  dts_file_str = f.read()

buff_start_addr, buff_size = get_rambuff_addr_size(dts_file_str)

# Pad start address (1 kB)
pad_value = 0x400
start_addr_pad_int = int(buff_start_addr, 16) + pad_value
start_addr_pad = f"0x{start_addr_pad_int:08x}"
buff_start_addr = start_addr_pad

#debug
# print(buff_start_addr,buff_size)

# From dts reserved size, determine VHDL ram_buff_size

int_buff_size = int(buff_size, 16)

# List to interpret size of reserved block for translating into VHDL address constants
possible_sizes = [[0x7B00000,0x8500000],[0xFB00000,0x10500000]]
# Mapping of size ranges
# 123-133 MB: ram_buff_size = 63.5 MB
# 251-261 MB: -> ram_buff_size = 127 MB

# ram_buff_size values corresponding to above ranges
size_list = [0x3F80000, 0x7F00000]

# List of sizes to add to start address to get top half offsets
top_half_sizes = [0x4000000, 0x8000000]

# List of top half addresses
top_half_list = [i + int(buff_start_addr, 16) for i in top_half_sizes]

# Default size to use
size_str = f"{size_list[0]:d}"
# print(size_str)
# Default top half to use
top_half_str = f'"0x{top_half_list[0]:08x}"'
# print(top_half_str)

buff_size_int = int(buff_size, 16)
# print(buff_size)

# Input size was within a range
size_found = False

for i in range(len(possible_sizes)):
  size_min = possible_sizes[i][0]
  size_max = possible_sizes[i][1]
  if buff_size_int >= size_min and buff_size_int <= size_max:
    size_str = f"{size_list[i]:d}"
    # print("size_str: " + size_str)
    top_half_str = f'"0x{top_half_list[i]:08x}"'
    # print("top_half_str: " + top_half_str)
    size_found = True
    break

# print("buff_start_addr: " + buff_start_addr)
# If we did not find a matching size, throw error
if size_found == False:
  print(f"autogen_res_mem.py [{bcolors.FAIL}ERROR{bcolors.ENDC}]: bad memory size. Not within specified range. Check dts file.")
  sys.exit()

# Add quotes to VHDL hex constant for start_address
buff_start_addr_str = f'"{buff_start_addr:s}"'
# print("buff_start_addr_str: " + buff_start_addr_str)

# Format as VHDL hex string
buff_start_addr_str = buff_start_addr_str.replace('"0x','')
buff_start_addr_str = 'x"' + buff_start_addr_str
# print("buff_start_addr_str: " + buff_start_addr_str)

top_half_str = top_half_str.replace('"0x','')
top_half_str = 'x"' + top_half_str
# print("top_half_str: " + top_half_str)


# Final checks
if not re.match(r'\d{5,20}', size_str):
  print(f"autogen_res_mem.py [{bcolors.FAIL}ERROR{bcolors.ENDC}]: (Sanity checking) Problem with size_str string. Abort.")
  print(f'autogen_res_mem.py [{bcolors.OKCYAN}INFO{bcolors.ENDC}]: (Sanity checking) Must be of form "123456"')
  sys.exit()
if not re.match(r'x"[abcdef\d]{8}"', buff_start_addr_str):
  print(f"autogen_res_mem.py [{bcolors.FAIL}ERROR{bcolors.ENDC}]: (Sanity checking) Problem with buff_start_addr_str string. Abort.")
  print(f'autogen_res_mem.py [{bcolors.OKCYAN}INFO{bcolors.ENDC}]: (Sanity checking) Must be of form "0x12345678"')
  sys.exit()
if not re.match(r'x"[abcdef\d]{8}"', top_half_str):
  print(f"autogen_res_mem.py [{bcolors.FAIL}ERROR{bcolors.ENDC}]: (Sanity checking) Problem with top_half_str string. Abort.")
  print(f'autogen_res_mem.py [{bcolors.OKCYAN}INFO{bcolors.ENDC}]: (Sanity checking) Must be of form "0x12345678"')
  sys.exit()

dma_file = "dma/src/dma_controller.vhd"

# Open original file, prepare substitution
with open(dma_file, "r") as f:
  dma_file_str = f.read()

output_str = "    ram_buff_size             : integer                        := %s;\n" %size_str
output_str += '    START_ADDRESS             : std_logic_vector(31 downto 0)  := %s;\n' %buff_start_addr_str
output_str += '    TOP_HALF_ADDRESS          : std_logic_vector(31 downto 0)  := %s;\n' %top_half_str

print(f'autogen_res_mem.py [{bcolors.OKCYAN}INFO{bcolors.ENDC}]: File used for autogenerated code: %s' %sys_usr_file)
print(f'autogen_res_mem.py [{bcolors.OKCYAN}INFO{bcolors.ENDC}]: Code block for insertion to %s follows below\n' %dma_file)

print(output_str + "\n")

f.close()

auto1 = "    --- BEGIN AUTOGENERATED MEMORY SETTINGS, DO NOT EDIT ---\n"
auto2 = "    --- END AUTOGENERATED MEMORY SETTINGS ---\n"

new_dma_file_str = re.sub(r"(?<=%s).*?(?=%s)" %(auto1,auto2), output_str, dma_file_str, flags=re.DOTALL)
# tp = re.compile(r"(?<=%s).*?(?=%s)" %(auto1,auto2), flags=re.DOTALL)
# print(tp.findall(dma_file_str))

# Write autogenerated block to source file
with open(dma_file, "w") as f:
  f.write(new_dma_file_str)

f.close()
print(f'autogen_res_mem.py [{bcolors.OKGREEN}OK{bcolors.ENDC}]: %s has been syncd with %s' %(dma_file, sys_usr_file))
