.PHONY: create synth impl

all: create synth impl

drs-ip:
	Hog/CreateProject.sh drs-ip

create: drs-ip
	Hog/CreateProject.sh trg-ip
	Hog/CreateProject.sh dma-ip
	Hog/CreateProject.sh tcl-to-bd
	Hog/CreateProject.sh readout-board

synth:
	Hog/LaunchSynthesis.sh readout-board

impl:
	Hog/LaunchImplementation.sh readout-board

clean:
	rm -rf VivadoProject/
