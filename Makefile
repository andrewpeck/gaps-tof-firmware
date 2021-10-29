SHELL := /bin/bash

.PHONY: create synth impl reg init

CCZE := $(shell command -v ccze 2> /dev/null)
ifndef CCZE
COLORIZE =
else
COLORIZE = | ccze -A
endif

IFTIME := $(shell command -v time 2> /dev/null)
ifndef IFTIME
TIMECMD =
else
TIMECMD = time -p
endif

list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

all: autogen_dma_mem create synth impl

init:
	git submodule update --init

reg:
	cd regmap && make

tcl_to_bd:
	$(TIMECMD) Hog/CreateProject.sh tcl_to_bd $(COLORIZE)

bd_to_tcl:
	$(TIMECMD) Hog/CreateProject.sh bd_to_tcl $(COLORIZE)

################################################################################
# Project creation / compilation
################################################################################

PROJECT_LIST = $(patsubst %/,%,$(patsubst Top/%,%,$(dir $(dir $(shell find Top/ -name hog.conf)))))
CREATE_LIST = $(addprefix create_,$(PROJECT_LIST))
OPEN_LIST = $(addprefix open_,$(PROJECT_LIST))

list_hog_projects:
	@echo $(PROJECT_LIST)

$(CREATE_LIST):
	@echo -------------------------------------------------------------------------------- $(COLORIZE)
	@echo Creating Project $(patsubst create_%,%,$@)                                       $(COLORIZE)
	@echo -------------------------------------------------------------------------------- $(COLORIZE)
	@time Hog/CreateProject.sh $(patsubst create_%,%,$@)                                   $(COLORIZE)

$(PROJECT_LIST):
	@echo -------------------------------------------------------------------------------- $(COLORIZE)
	@echo Launching Hog Workflow $@                                                        $(COLORIZE)
	@echo -------------------------------------------------------------------------------- $(COLORIZE)
	@time Hog/LaunchWorkflow.sh $@                                                         $(COLORIZE)

$(OPEN_LIST):
	vivado Projects/$(patsubst open_%,%,$@)/$(patsubst open_%,%,$@).xpr &

fpgaman_bin:
	cd util; python3 create_fpga_manager_bin.py

autogen_dma_mem:
	python3 util/autogen_res_mem.py

clean:
	rm -rf Projects/
