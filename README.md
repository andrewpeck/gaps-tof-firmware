# DRS4 Readout Board + Master Trigger Firmware

[[_TOC_]]

## Organization

<pre>
readout-firmware/
  ├── <a href="./Top">Top</a>      : Top level project configuration files for HOG
  ├── <a href="./bd">bd</a>       : Block diagram files
  ├── <a href="./common">common</a>   : Files common to MT and RB design
  ├── <a href="./dma">dma</a>      : Files for DMA driver
  ├── <a href="./drs">drs</a>      : Files for DRS4 control
  ├── <a href="./ip">ip</a>       : Vivado IP cores
  ├── <a href="./regmap">regmap</a>   : Register XML to VHDL tools
  ├── <a href="./trigger">trigger</a>  : Master Trigger Design
  ├── <a href="./util">util</a>     : Helper scripts for build system
  ├── <a href="./xdc">xdc</a>      : Xilinx XDC constraint files
  ├── <a href="https://gitlab.cern.ch/hog/Hog">Hog</a>      : Submodule containing the HOG project
  ├── Projects : Auto-generated directory containing the Vivado projects
  └── <a href="./plnx">plnx</a>     : PetaLinux source files and docs
</pre>

## Software dependencies

* Xilinx tools
  * Vivado 2020.1
* Build system
  * git
  * make
  * python3.6+
* Optional
  * emacs

## Register Access

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

* [Readout Board Address Table](regmap/rb_address_table.org)
* [Master Trigger Address Table](regmap/mt_address_table.org)

To update the address table in the project, make edits directly to `rb_registers.xml` or
`mt_registers.xml`, then build using

```bash
make reg
```

## Building the Firmware

### Special note for 2020.1 and hardware generation

Vivado 2020.1 cannot be used with Hog to export hardware `.xsa` out of the box due to a bug Xilinx
shipped in that version. Implement either of two work arounds below.

 1. Stock 2020.1: ensure bitstream successfully generated. Open BD or Implemented Design:
    File->Export->Export Hardware (Platform type=Fixed), next-> Check include bitstream, next->set
    file name/path->finish.
 2. Fix 2020.1 with Xilinx "tactical patch". See
    <https://www.xilinx.com/support/answers/75210.html>. If using this option, no further steps are
    required when using the Hog build system.

### Build instructions

This firmware is using the HOG framework as a build system:

* HOG Documentation: <http://hog-user-docs.web.cern.ch>
* HOG Source Code: <https://gitlab.cern.ch/hog/Hog>

Clone project recursively to pull all HOG scripts

```bash
git clone --recursive https://gitlab.com/ucla-gaps-tof/firmware.git
```

The firmware can then be built with:

```bash
make readout_board_zx3
make readout_board_zx2
make trigger_board
```

a list of Make targets will be displayed by typing:

```bash
make
```

**To use any of these commands you need to make sure that Vivado is in
your path**, i.e. if you type Vivado into the terminal it should open
Vivado.

To make sure the environment variables always set, modify your `.bashrc`
to contain a similar command as below, depending on where you installed
Vivado.

```bash
source /opt/Xilinx/Vivado/2020.1/settings64.sh
```

The scripts use only very primitive bash and otherwise use the Vivado
TCL shell, so there should be no external dependencies.

Best practice is for released builds the entire repo should be cloned
from scratch and built from the clean cloned repository to ensure that
no files are missing, the build directory is clean, and so on.

## Data Flow 

![data-flow](./drs/data-flow.svg)

## Dataformat

  | Field      | Len             | Description                                                                                                                                                                                   |
  |:-----------|:----------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | HEAD       | `[15:0]`        | 0xAAAA                                                                                                                                                                                        |
  | STATUS     | `[15:0]`        | `[0]` = empty event fragment <br> `[1]` = drs was busy (lost trigger) <br> `[2]` = locked, `[3]` = locked (past second) `[15:4]`= 12 bit temperature                                          |
  | LEN        | `[15:0]`        | length of packet in 2 byte words                                                                                                                                                              |
  | ROI        | `[15:0]`        | size of region of interest                                                                                                                                                                    |
  | DNA        | `[63:0]`        | Zynq7000 Device DNA                                                                                                                                                                           |
  | FW\_HASH   | `[15:0]`        | First 16 bits of Git Hash                                                                                                                                                                     |
  | ID         | `[15:0]`        | `[15:8]` = readout board ID <br> `[7:0]` = reserved <br>                                                                                                                                      |
  | CH\_MASK   | `[15:0]`        | `[8:0]` = Channel Enable Mask '1'=ON, `[15:9]` reserved                                                                                                                                           |
  | EVENT\_CNT | `[31:0]`        | Event ID Received From Trigger                                                                                                                                                                |
  | DTAP0      | `[15:0]`        | DTAP0 Frequency in 100Hz                                                                                                                                                                      |
  | DRS_TEMP   | `[15:0]`        | DRS temperature, written by software                                                                                                                                                          |
  | TIMESTAMP  | `[47:0]`        | \# of 33MHz clocks elapsed since resync                                                                                                                                                       |
  | PAYLOAD    | 0 to XXXX words | `HEADER[15:0]` = Channel ID <br> ----- begin block data ----- <br> `DATA[13:0]` = ADC data <br> `DATA[15:14]` parity <br> ----- end block: len = ROI words ----- <br> `TRAILER[31:0]` = crc32 |
  | STOP CELL  | `[15:0]`        | Stop cell of the DRS                                                                                                                                                                          |
  | CRC32      | `[31:0]`        | Packet CRC (excluding Trailer)                                                                                                                                                                |
  | TAIL       | `[15:0]`        | 0x5555                                                                                                                                                                                        |

## Master Trigger Data Format

  | Field     | Len      | Description                                        |
  |:----------|:---------|:---------------------------------------------------|
  | START     | `[0:0]`  | '1' to start                                       |
  | TRIGGER   | `[0:0]`  | '1' initiates a trigger; '0' for an event fragment |
  | CH\_MASK  | `[7:0]`  | bitfield set to '1' to readout a channel           |
  | EVENT\_ID | `[31:0]` | Event ID                                           |
  | CMD       | `[1:0]`  | 3=resync                                           |
  | CRC8      | `[7:0]`  | lfsr(7:0)=1+x^2+x^4+x^6+x^7+x^8                    |

## Local Trigger Data Format

?

## Master Trigger External IO

  | Signal       | Assignment | Description                                                                                                                                 |
  |:-------------|:-----------|:--------------------------------------------------------------------------------------------------------------------------------------------|
  | TIU Busy     | EXT_IN0    | LVDS IN: Busy acknowledgment from the TIU. Trigger should be deasserted only after busy is received.                                        |
  | TIU Timecode | EXT_IN1    | LVDS IN: Asynchronous serial input containing the GPS timestamp.                                                                            |
  | TIU Event ID | EXT_OUT0   | LVDS OUT: Asynchronous serial output containing the event ID                                                                                |
  | TIU Trigger  | EXT_OUT1   | LVDS OUT: Trigger output from the MT to TIU. Asynchronous level which should not be deasserted until the BUSY is received back from the TIU |

## Gitlab runner registration

Some simple instructions for registering a Gitlab runner

1. Install gitlab-runner
   * <https://docs.gitlab.com/runner/install/>
2. Execute `gitlab-runner register`
3. At the prompt of "Please enter the gitlab-ci coordinator URL (e.g.
    <https://gitlab.com/>):", enter: `https://gitlab.com/`
4. At the prompt of "Please enter the gitlab-ci token for this
    runner:", enter the token that you get from Settings -&gt; CI/CD
    -&gt; Runners --&gt; Set up a specific Runner manually.
5. At the prompt of "Please enter the gitlab-ci description for this
    runner:", give it a name:
6. At the prompt of "Please enter the gitlab-ci tags for this runner
    (comma separated):", enter `hog`
7. At the prompt of: "Please enter the executor: docker+machine,
    docker-ssh+machine, kubernetes, parallels, virtualbox, docker-ssh,
    shell, ssh, custom, docker:", enter: `shell`

Now you can simply start the runner (`gitlab-runner run`). Make sure
Vivado is in the path.
