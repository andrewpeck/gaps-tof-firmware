Firmware repository for UCLA DRS4 readout board

Clone the repository with:

    git clone https://uhhepvcs.phys.hawaii.edu/gaps-ucla/readout-firmware.git
    cd readout-firmware && git submodule update --init 

## Organization 

    readout-firmware/
      ├── Hog : Submodule containing the HOG project
      ├── Top : Top level project configuration files for HOG
      ├── bd  : Block diagram files
      ├── tcl : TCL scripts for ip core creation
      ├── ip  : Holds both user and Vivado IP cores
      ├── dma : Files for DMA driver
      ├── drs : Files for DRS4 control
      ├── trg : Files for AXI-SLAVE trigger interface 
      └── xdc : Xilinx XDC constraint files

## Building the Firmware

This firmware is using the HOG framework as a build system: 
 * HOG Documentation: http://hog-user-docs.web.cern.ch
 * HOG Source Code: https://gitlab.cern.ch/hog/Hog

Currently the firmware is built around three separately compiled IP cores which are then integrated together into a common project through the graphical block diagram generator. 

The IP cores can be built with the following commands. Note that because the these blocks are constructed as standalone IP cores, they go through the entire out-of-context synthesis process at the time of project creation. No further action is required with these IPs. 

    Hog/CreateProject.sh trg-ip 
    Hog/CreateProject.sh dma-ip 
    Hog/CreateProject.sh drs-ip 
    
After that, the combined project can be created with the command 

    Hog/CreateProject.sh readout-board
    
Synthesis can be launched with the command

    Hog/LaunchSynthesis.sh readout-board
    
Implementation can be launched with the command

    Hog/LaunchImplementation.sh readout-board

A more streamlined HDL based project organization is forthcoming...

**To use any of these commands you need to make sure that vivado is in your path**, i.e. if you type vivado into the terminal it should open vivado. The scripts use only very primitive bash and otherwise use the vivado TCL shell, so there should be no external dependencies. 

## Block Design Creation

HOG wrappers provide facilities for creation of TCL files from Block Designs, and Block Designs from TCL.

#### To export a TCL file from a block design: 

    Hog/CreateProject.sh bd-to-tcl 

#### To generate a block design from a TCL file:

    Hog/CreateProject.sh tcl-to-bd

Block designs are easier to work with, but do not play well with diff and have more issues with version lock-in. 

Both tcl and bd should be committed to the repository. For working with the same (or close) vivado versions the bd file can just be opened directly (and the tcl should be exported after any changes are made).

The tcl-to-bd flow can be used when changing versions. There is still some version-lock-in but efforts were made to minimize it. 

### 2018.2 Compatibility

One note. Newer versions of Vivado add the flag ```force``` onto the end of the ```assign_bd_address``` commands in the ```readout-board-bd.tcl``` file. 

The force flag does not exist in Vivado 2018.2 for example. To keep the TCL file compatible between versions you can change the lines from:

    assign_bd_address -offset 0x80000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs drs_top_0/S_AXI_LITE/reg0] -force
    
to 

    assign_bd_address -offset 0x80000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs drs_top_0/S_AXI_LITE/reg0] 

## CCZE

If you have the program [ccze](https://github.com/cornet/ccze) installed, it is very useful for viewing log files since it provides reasonably good syntax highlighting. 

You can use it with e.g. 

    Hog/CreateProject.sh readout-board | ccze -A
