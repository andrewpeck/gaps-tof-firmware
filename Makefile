.PHONY: create synth impl

CCZE := $(shell command -v ccze 2> /dev/null)
ifndef CCZE
COLORIZE =
else
COLORIZE = | ccze -A
endif

all: create synth impl

reg:
	cd regmap && make

drs-ip:
	Hog/CreateProject.sh drs-ip $(COLORIZE)
create: drs-ip
	Hog/CreateProject.sh trg-ip $(COLORIZE)
	Hog/CreateProject.sh dma-ip $(COLORIZE)
	Hog/CreateProject.sh tcl-to-bd $(COLORIZE)
	Hog/CreateProject.sh readout-board $(COLORIZE)

synth:
	Hog/LaunchSynthesis.sh readout-board $(COLORIZE)

impl:
	Hog/LaunchImplementation.sh readout-board $(COLORIZE)

clean:
	rm -rf VivadoProject/
