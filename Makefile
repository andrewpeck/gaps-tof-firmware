.PHONY: create synth impl reg init

CCZE := $(shell command -v ccze 2> /dev/null)
ifndef CCZE
COLORIZE =
else
COLORIZE = | ccze -A
endif

list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

all: create synth impl

init:
	git submodule update --init

reg:
	cd regmap && make

tcl_to_bd:
	Hog/CreateProject.sh tcl_to_bd $(COLORIZE)

bd_to_tcl:
	Hog/CreateProject.sh bd_to_tcl $(COLORIZE)

create:
	Hog/CreateProject.sh readout_board $(COLORIZE)

synth:
	Hog/LaunchSynthesis.sh readout_board $(COLORIZE)

impl:
	Hog/LaunchImplementation.sh readout_board $(COLORIZE)

clean:
	rm -rf VivadoProject/
