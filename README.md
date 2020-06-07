# readout-firmware

Firmware repository for UCLA DRS4 readout board

These files are used to generate a project file for GAPS Readout V2.0 Board. 

This firmware is using the HOG framework as a build system: 
 * HOG Documentation: hog-user-docs.web.cern.ch
 * HOG Source Code: https://gitlab.cern.ch/hog/Hog

Currently the firmware is built around three separately compiled IP cores which are then integrated together into a common project through the graphical block diagram generator. 

The IP cores can be built with the commands: 
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

*To use any of these commands you need to make sure that vivado is in your path*, i.e. if you type vivado into the terminal it should open vivado. The scripts use only very primitive bash and otherwise use the vivado TCL shell, so there should be no external dependencies. 
