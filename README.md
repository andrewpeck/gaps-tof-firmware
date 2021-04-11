DRS4 Readout Board Firmware
------------

[[_TOC_]]

Organization
------------

``` {.example}
readout-firmware/
  ├── Hog             : Submodule containing the HOG project
  ├── Top             : Top level project configuration files for HOG
  ├── bd              : Block diagram files
  ├── regmap          : Register XML to VHDL tools
  ├── tcl             : TCL scripts for ip core creation
  ├── ip              : Holds both user and Vivado IP cores
  ├── dma             : Files for DMA driver
  ├── drs             : Files for DRS4 control
  ├── xdc             : Xilinx XDC constraint files
  └── VivadoProject   : Auto-generated directory containing the Vivado project

```

Register Access
---------------

Firmware registers mapped to a Wishbone-like A32/D32 interface, which is
accessed through an AXI⟷Wishbone Bridge

From the Zynq, it appears as a memory-mapped into an address space,
starting at `Base Address=0x8000_0000` (with a maximum address of
0x8000\_FFFF, giving an effective address space of 16 bits or 65536
registers).

An interactive client can read and write from registers, by calling
reg\_interface.py

A python library `rw_reg.py` allows for register access by name

### Address Table

The address table is defined in a "templated" XML file: *registers.xml*

A convenient document describing the address table can be seen at:

-   [DRS Address Table](regmap/address_table.org)

Building the Firmware
---------------------

This firmware is using the HOG framework as a build system:

-   HOG Documentation: <http://hog-user-docs.web.cern.ch>
-   HOG Source Code: <https://gitlab.cern.ch/hog/Hog>

Clone project recursively to pull all HOG scripts

``` {.example}
git clone --recursive https://gitlab.com/ucla-gaps-tof/firmware.git
```

The firmware can then be built with:

``` {.example}
make all
```

a list of Make targets will be displayed by typing:

``` {.example}
make
```

**To use any of these commands you need to make sure that Vivado is in
your path**, i.e. if you type Vivado into the terminal it should open
Vivado.

To make sure the environment variables always set, modify your `.bashrc`
to contain a similar command as below, depending on where you installed
Vivado.

``` {.example}
source /home/your_usr_name/Xilinx/Vivado/2019.2/settings64.sh
```

The scripts use only very primitive bash and otherwise use the Vivado
TCL shell, so there should be no external dependencies.

Best practice is for released builds the entire repo should be cloned
from scratch and built from the clean cloned repository to ensure that
no files are missing, the build directory is clean, and so on.

Block Design Creation
---------------------

HOG wrappers provide facilities for creation of TCL files from Block
Designs, and Block Designs from TCL.

To export a TCL file from a block design:

``` {.example}
Hog/CreateProject.sh bd-to-tcl
```

To generate a block design from a TCL file:

``` {.example}
Hog/CreateProject.sh tcl-to-bd
```

Block designs are easier to work with, but do not play well with diff
and have more issues with version lock-in.

Both tcl and bd should be committed to the repository. For working with
the same (or close) Vivado versions the bd file can just be opened
directly (and the tcl should be exported after any changes are made).

The tcl-to-bd flow can be used when changing versions. There is still
some version-lock-in but efforts were made to minimize it.

### 2018.2 Compatibility

One note. Newer versions of Vivado add the flag `force` onto the end of
the `assign_bd_address` commands in the `readout-board-bd.tcl` file.

The force flag does not exist in Vivado 2018.2 for example. To keep the
TCL file compatible between versions you can change the lines from:

``` {.example}
assign_bd_address -offset 0x80000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs drs_top_0/S_AXI_LITE/reg0] -force
```

to

``` {.example}
assign_bd_address -offset 0x80000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs drs_top_0/S_AXI_LITE/reg0]
```

Dataformat
----------

  | Field      | Len             | Description                                                                                                                                                                                               |
  | :----      | :---------      | :-------------                                                                                                                                                                                            |
  | HEAD       | \[15:0\]        | 0xAAAA                                                                                                                                                                                                    |
  | STATUS     | \[15:0\]        | \[0\] =sync\_err <br> \[1\] = drs was busy (lost trigger) <br> \[15:1\]=reserved                                                                                                                          |
  | LEN        | \[15:0\]        | length of packet in 2 byte words                                                                                                                                                                          |
  | ROI        | \[15:0\]        | size of region of interest                                                                                                                                                                                |
  | DNA        | \[63:0\]        | Zynq7000 Device DNA                                                                                                                                                                                       |
  | FW\_HASH   | \[15:0\]        | First 16 bits of Git Hash                                                                                                                                                                                 |
  | ID         | \[15:0\]        | \[15:8\] = readout board ID <br> \[7:1\] = reserved <br> \[0\] = drs # 0 or # 1                                                                                                                           |
  | CH\_MASK   | \[15:0\]        | Channel Enable Mask '1'=ON <br> should be either upper 8 bits or lower 8 <br> depending on the chip id                                                                                                    |
  | EVENT\_CNT | \[31:0\]        | Event ID Received From Trigger                                                                                                                                                                            |
  | TIMESTAMP  | \[47:0\]        | \# of 33MHz clocks elapsed since resync                                                                                                                                                                   |
  | PAYLOAD    | 0 to XXXX words | HEADER\[15:0\] = Channel ID <br> ----- begin block data ----- <br> data bits \[13:0\] = ADC data <br> data bits \[15:14\] parity <br> ----- end block: len = ROI words ----- <br> trailer\[31:0\] = crc32 |
  | STOP CELL  | \[15:0\]        | Stop cell of the DRS                                                                                                                                                                                      |
  | CRC32      | \[31:0\]        | Packet CRC (excluding Trailer)                                                                                                                                                                            |
  | TAIL       | \[15:0\]        | 0x5555                                                                                                                                                                                                    |

Trigger Data Format
-------------------

  | Field     | Len       | Description                                                                                            |
  | :-------- | :-------- | :-------------                                                                                         |
  | START     | \[0\]     | 1'b1 = Start bit                                                                                       |
  | CMD       | \[0\]     | 1'b0 = resync <br> 1'b1 = trigger                                                                      |
  | CH\_MASK  | \[15:0\]  | bitfield set to '1' to readout a chanel <br> \[7:0\]=DRS0 channels 7:0 <br> \[15:8\]=DRS1 channels 7:0 |
  | EVENT\_ID | \[31:0\]  | Event ID                                                                                               |

Gitlab runner registration
==========================

Some simple instructions for registering a Gitlab runner

1.  Install gitlab-runner
    -   <https://docs.gitlab.com/runner/install/>
2.  Execute `gitlab-runner register`
3.  At the prompt of "Please enter the gitlab-ci coordinator URL (e.g.
    <https://gitlab.com/>):", enter:
```
https://gitlab.com/
```
4.  At the prompt of "Please enter the gitlab-ci token for this
    runner:", enter the token that you get from Settings -&gt; CI/CD
    -&gt; Runners --&gt; Set up a specific Runner manually.
5.  At the prompt of "Please enter the gitlab-ci description for this
    runner:", give it a name:
6.  At the prompt of "Please enter the gitlab-ci tags for this runner
    (comma separated):", enter
```
hog
```
7.  At the prompt of: "Please enter the executor: docker+machine,
    docker-ssh+machine, kubernetes, parallels, virtualbox, docker-ssh,
    shell, ssh, custom, docker:", enter:
```
shell
```
Now you can simply start the runner (`gitlab-runner run`). Make sure
Vivado is in the path.
