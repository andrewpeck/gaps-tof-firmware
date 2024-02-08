## Table of Contents <span class="tag" tag-name="TOC_4"><span class="smallcaps">TOC_4</span></span>

- [Organization](#organization)
- [Software dependencies](#software-dependencies)
- [Register Access](#register-access)
  - [Address Table](#address-table)
- [Building the Firmware](#building-the-firmware)
  - [Special note for 2020.1 and hardware
    generation](#special-note-for-20201-and-hardware-generation)
  - [Build instructions](#build-instructions)
- [DRS Data Flow](#drs-data-flow)
- [RB Dataformat](#rb-dataformat)
- [Master Trigger to RB Data Format](#master-trigger-to-rb-data-format)
- [Local Trigger Data Format](#local-trigger-data-format)
- [Master Trigger DAQ Data Format](#master-trigger-daq-data-format)
- [Master Trigger External IO](#master-trigger-external-io)
- [Trigger Latency](#trigger-latency)
- [Gitlab runner registration](#gitlab-runner-registration)

## Organization

    readout-firmware/
      ├── Top      : Top level project configuration files for HOG
      ├
      ├── common   : Files common to MT and RB design
      ├── bd       : Block diagram files
      ├── dma      : Files for DMA driver
      ├── drs      : Files for DRS4 control
      ├── ltb      : Files for Local Trigger Board
      ├── trg      : Files for Master Trigger Board
      ├── ip       : Vivado IP cores
      ├
      ├── regmap   : Register XML to VHDL tools
      ├── trigger  : Master Trigger Design
      ├── util     : Helper scripts for build system
      ├── xdc      : Xilinx XDC constraint files
      ├── Hog      : Submodule containing the HOG project
      ├── Projects : Auto-generated directory containing the Vivado projects
      └── plnx     : PetaLinux source files and docs

## Software dependencies

- Xilinx tools
  - Vivado 2020.1
- Build system
  - git
  - make
  - python3.6+
- Optional
  - emacs

## Register Access

Firmware registers mapped to a Wishbone-like A32/D32 interface, which is
accessed through an AXI⟷Wishbone Bridge

From the Zynq, it appears as a memory-mapped into an address space,
starting at `Base Address=0x8000_0000` (with a maximum address of
0x8000_FFFF, giving an effective address space of 16 bits or 65536
registers).

An interactive client can read and write from registers, by calling
reg_interface.py

A python library `rw_reg.py` allows for register access by name

### Address Table

The address table is defined in a "templated" XML file: *registers.xml*

A convenient document describing the address table can be seen at:

- [Readout Board Address Table](regmap/rb_address_table.org)
- [Master Trigger Address Table](regmap/mt_address_table.org)

To update the address table in the project, make edits directly to
`rb_registers.xml` or `mt_registers.xml`, then build using

``` shell
make reg
```

## Building the Firmware

### Special note for 2020.1 and hardware generation

Vivado 2020.1 cannot be used with Hog to export hardware `.xsa` out of
the box due to a bug Xilinx shipped in that version. Implement either of
two work arounds below.

1.  Stock 2020.1: ensure bitstream successfully generated. Open BD or
    Implemented Design: File-\>Export-\>Export Hardware (Platform
    type=Fixed), next-\> Check include bitstream, next-\>set file
    name/path-\>finish.
2.  Fix 2020.1 with Xilinx "tactical patch". See
    <https://www.xilinx.com/support/answers/75210.html>. If using this
    option, no further steps are required when using the Hog build
    system.

### Build instructions

This firmware is using the HOG framework as a build system:

- HOG Documentation: <http://hog-user-docs.web.cern.ch>
- HOG Source Code: <https://gitlab.cern.ch/hog/Hog>

Clone project recursively to pull all HOG scripts

``` shell
git clone --recursive https://gitlab.com/ucla-gaps-tof/firmware.git
```

The firmware can then be built with:

``` shell
make readout_board_zx3
make readout_board_zx2
make trigger_board
```

a list of Make targets will be displayed by typing:

``` shell
make
```

**To use any of these commands you need to make sure that Vivado is in
your path**, i.e. if you type Vivado into the terminal it should open
Vivado.

To make sure the environment variables always set, modify your `.bashrc`
to contain a similar command as below, depending on where you installed
Vivado.

``` shell
source /opt/Xilinx/Vivado/2020.1/settings64.sh
```

The scripts use only very primitive bash and otherwise use the Vivado
TCL shell, so there should be no external dependencies.

Best practice is for released builds the entire repo should be cloned
from scratch and built from the clean cloned repository to ensure that
no files are missing, the build directory is clean, and so on.

## DRS Data Flow

<figure>
<img src="./drs/data-flow.svg" />
<figcaption>data-flow</figcaption>
</figure>

## RB Dataformat

| Field     | Len             | Description                                                           |
|-----------|-----------------|-----------------------------------------------------------------------|
| HEAD      | `[15:0]`        | 0xAAAA                                                                |
| STATUS    | `[15:0]`        | `[0]` = empty event fragment                                          |
|           |                 | `[1]` = drs was busy (lost trigger)                                   |
|           |                 | `[2]` = locked                                                        |
|           |                 | `[3]` = locked (past second)                                          |
|           |                 | `[15:4]` = 12 bit FPGA temperature                                    |
| LEN       | `[15:0]`        | length of packet in 2 byte words                                      |
| ROI       | `[15:0]`        | size of region of interest                                            |
| DNA       | `[15:0]`        | Zynq7000 Device DNA bits \[63:48\] ^ \[47:32\] ^ \[31:16\] ^ \[15:0\] |
| RSVD0     | `[15:0]`        | Reserved                                                              |
| RSVD1     | `[15:0]`        | Reserved                                                              |
| RSVD2     | `[15:0]`        | Reserved                                                              |
| FW_HASH   | `[15:0]`        | First 16 bits of Git Hash                                             |
| ID        | `[15:0]`        | `[15:8]` = readout board ID                                           |
|           |                 | `[7:0]` = reserved                                                    |
| CH_MASK   | `[15:0]`        | `[8:0]` = Channel Enable Mask '1'=ON                                  |
|           |                 | `[15:9]` reserved                                                     |
| EVENT_CNT | `[31:0]`        | Event ID Received From Trigger                                        |
| DTAP      | `[15:0]`        | DTAP Frequency in 100Hz                                               |
| DRS_TEMP  | `[15:0]`        | DRS temperature, written by software                                  |
| TIMESTAMP | `[47:0]`        | \# of 33MHz clocks elapsed since resync                               |
| PAYLOAD   | 0 to XXXX words | `HEADER[15:0]` = Channel ID                                           |
|           |                 | —– begin block data —–                                                |
|           |                 | `DATA[13:0]` = ADC data `DATA[15:14]` parity                          |
|           |                 | —– end block: len = ROI words —–                                      |
|           |                 | `TRAILER[31:0]` = crc32                                               |
| STOP CELL | `[15:0]`        | Stop cell of the DRS                                                  |
| CRC32     | `[31:0]`        | Packet CRC (excluding Trailer)                                        |
| TAIL      | `[15:0]`        | 0x5555                                                                |

## Master Trigger to RB Data Format

| Field    | Len      | Description                                        |
|----------|----------|----------------------------------------------------|
| START    | `[0:0]`  | '1' to start                                       |
| TRIGGER  | `[0:0]`  | '1' initiates a trigger; '0' for an event fragment |
| CH_MASK  | `[7:0]`  | bitfield set to '1' to readout a channel           |
| EVENT_ID | `[31:0]` | Event ID                                           |
| CMD      | `[1:0]`  | 3=resync                                           |
| CRC8     | `[7:0]`  | lfsr(7:0)=1+x<sup>2+x</sup>4+x<sup>6+x</sup>7+x^8  |

## Local Trigger Data Format

<https://gaps1.astro.ucla.edu/wiki/gaps/index.php?title=Local_Trigger_Board_Operation>

The LT to MT link consists of 2 LVDS pairs per MT.

This can be optionally expanded to 3 pairs with an unstuffed isolator,
in case of bandwidth requirements.

Each MT pair transmits at 200 Mbps, on an *asynchronous* clock.

The data format on each pair consists of a start bit, followed by the
data payload.

The entire data packet consists of 16 bits of payload (8 channels of
low, medium, and high threshold).

Since it is divided into 2 links, this means 8 bits / link + 2 start
bits per trigger.

``` example
//      | no hit| thr0 | thr1 | thr2
//----------------------------------
// bit0 |    0  |  0   |  1   |  1
// bit1 |    0  |  1   |  0   |  1

//LINK0  = START bit +paddles bit 0 (9 bits total)
//LINK1 = START bit +paddles bit 1 (9 bits total)
```

## Master Trigger DAQ Data Format

| Field         | Len      | Description                                                       |
|---------------|----------|-------------------------------------------------------------------|
| HEADER        | `[31:0]` | 0xAAAA_AAAA                                                       |
| EVENT_CNT     | `[31:0]` | Event counter                                                     |
| TIMESTAMP     | `[31:0]` | Internal timestamp at the time of trigger (1 unit = 10 ns)        |
| TIU_TIMESTAMP | `[31:0]` | Timestamp at the edge of the TIU GPS (1 unit = 10 ns)             |
| TIU_GPS       | `[47:0]` | Second received from the TIU (format?)                            |
| TRIG_SOURCE   | `[15:0]` | Bitmask showing all trigger sources                               |
|               |          | 5: gaps trigger                                                   |
|               |          | 6: any trigger                                                    |
|               |          | 7: forced trigger                                                 |
|               |          | 8: track trigger                                                  |
|               |          | 9: central track trigger                                          |
|               |          | other bits unallocated                                            |
| BOARD_MASK    | `[31:0]` | 25 bits indicating boards which local trigger boards are read out |
| HITS          | –        | Variable sized, 16 bits / board \* n_boards                       |
| PAD           | `[15:0]` | Optional, only here if the \# of LTBs read is odd                 |
| CRC           | `[31:0]` | CRC32, same polynomial as the RB                                  |
| TRAILER       | `[31:0]` | 0x5555_5555                                                       |

## Master Trigger External IO

| Signal       | Assignment | Description                                                                                                                                 |
|--------------|------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| TIU Busy     | EXT_IN0    | LVDS IN: Busy acknowledgment from the TIU. Trigger should be deasserted only after busy is received.                                        |
| TIU Timecode | EXT_IN1    | LVDS IN: Asynchronous serial input containing the GPS timestamp.                                                                            |
| TIU Event ID | EXT_OUT0   | LVDS OUT: Asynchronous serial output containing the event ID                                                                                |
| TIU Trigger  | EXT_OUT1   | LVDS OUT: Trigger output from the MT to TIU. Asynchronous level which should not be deasserted until the BUSY is received back from the TIU |

| Pin        | Function          |
|------------|-------------------|
| ext_io(0)  | ext_trigger input |
| ext_io(1)  | –                 |
| ext_io(2)  | SDA               |
| ext_io(3)  | SCL               |
| ext_io(5)  | hk_ext_clk;       |
| ext_io(6); | hk_ext_miso       |
| ext_io(7)  | hk_ext_mosi;      |
| ext_io(8)  | hk_ext_cs_n(0);   |
| ext_io(9)  | hk_ext_cs_n(1);   |
| ext_io(10) | trigger mirror    |
| ext_io(12) | –                 |
| ext_io(13) | –                 |

## Trigger Latency

| Item                                 | Delay (ns) | Source               |
|--------------------------------------|------------|----------------------|
| LTB Analog Frontend (AD8014)         | 0.5        | estimate             |
| LTB Analog Frontend (ADCMP601)       | 3.5        | datasheet            |
| LTB Input Routing                    | 1.5        | estimate             |
| LTB FPGA Input Delay                 | 3.6        | Vivado timing report |
| LTB FPGA Firmware                    | 50         | measurement          |
| LTB FPGA Output Delay                | 4.2        | Vivado timing report |
| LTB Output Routing                   | 1          | estimate             |
| LTB Differential Buffer (DS90LV027A) | 1.5        | datasheet            |
| Cable (10 ft)                        | 13         | measurement          |
| DSI Isolator (ADN4654)               | 4          | datasheet            |
| DSI to MTB FPGA Routing              | 1.5        | estimate             |
| MTB FPGA Input Delay                 | 2          | timing report        |
| MTB FPGA LTB Deserialization         | 45         | 9 bits @ 200 MHz     |
| MTB FPGA Firmware                    | 60         | measurement (ILA)    |
| MTB FPGA Output Delay                | 3.9        | timing report        |
| MTB FPGA to Output Routing           | 1          | estimate             |
| MTB Output Buffer (DS90LV031ATMTC)   | 2          | datasheet            |
| Total                                | 223.2      |                      |

## Gitlab runner registration

Some simple instructions for registering a Gitlab runner

1.  Install gitlab-runner

    - <https://docs.gitlab.com/runner/install/>

2.  Execute `gitlab-runner register`

3.  At the prompt of "Please enter the gitlab-ci coordinator URL (e.g.
    <https://gitlab.com/>):", enter: `https://gitlab.com/`

4.  At the prompt of "Please enter the gitlab-ci token for this
    runner:", enter the token that you get from Settings -\> CI/CD -\>
    Runners –\> Set up a specific Runner manually.

5.  At the prompt of "Please enter the gitlab-ci description for this
    runner:", give it a name:

6.  At the prompt of "Please enter the gitlab-ci tags for this runner
    (comma separated):", enter `hog`

7.  At the prompt of: "Please enter the executor: docker+machine,
    docker-ssh+machine, kubernetes, parallels, virtualbox, docker-ssh,
    shell, ssh, custom, docker:", enter: `shell`

Now you can simply start the runner (`gitlab-runner run`). Make sure
Vivado is in the path.

## Updating mapping

Note: this requires an installation of babashka
<https://github.com/babashka/babashka>

1.  clone the firmware

2.  update the mapping

cd trigger/src/trg make

1.  Commit the updated files, push to devel of the repo

git add mapping.csv rb_map.vhd trigger.vhd git commit -m "mtb: Update
link mapping"

1.  Open a merge request from devel -\> master

## Updating trigger

If you send me a new version of the trigger definitions it is trivial to
recompile firmware with whatever you want. The current definitions I got
from you are here:
<https://gitlab.com/ucla-gaps-tof/firmware/-/blob/develop/trigger/src/trg/generate_triggers.bb>
For reference in case I am not available sometime and you need things in
a rush the to update the new firmware is:

1.  clone the firmware
2.  edit generate_triggers.bb to your liking
3.  run Make in the same directory. You need awk and babashka installed
4.  Commit the updated files, push to devel of the repo
5.  Open a merge request from devel -\> master
