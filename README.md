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

## CCZE

If you have the program [ccze](https://github.com/cornet/ccze) installed, it is very useful for viewing log files since it provides reasonably good syntax highlighting. 

You can use it with e.g. 

    Hog/CreateProject.sh readout-board | ccze -A
