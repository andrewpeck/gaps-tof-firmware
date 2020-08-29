.PHONY: create synth impl

all: create synth impl

create:
	Hog/CreateProject.sh trg-ip
	Hog/CreateProject.sh dma-ip
	Hog/CreateProject.sh drs-ip
	Hog/CreateProject.sh tcl-to-bd
	Hog/CreateProject.sh readout-board

synth:
	Hog/LaunchSynthesis.sh readout-board

impl:
	Hog/LaunchImplementation.sh readout-board
