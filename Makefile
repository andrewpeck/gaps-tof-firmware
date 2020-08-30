.PHONY: create synth impl reg init

CCZE := $(shell command -v ccze 2> /dev/null)
ifndef CCZE
COLORIZE =
else
COLORIZE = | ccze -A
endif

all: create synth impl

init:
	git submodule update --init

reg:
	cd regmap && make

drs_ip:
	Hog/CreateProject.sh drs_ip $(COLORIZE)

trg_ip:
	Hog/CreateProject.sh trg_ip $(COLORIZE)

dma_ip:
	Hog/CreateProject.sh dma_ip $(COLORIZE)

tcl_to_bd:
	Hog/CreateProject.sh tcl_to_bd $(COLORIZE)

create: drs_ip trg_ip dma_ip tcl_to_bd
	Hog/CreateProject.sh readout_board $(COLORIZE)

impl:
	Hog/LaunchSynthesis.sh readout_board $(COLORIZE)
	Hog/LaunchImplementation.sh readout_board $(COLORIZE)

clean:
	rm -rf VivadoProject/
