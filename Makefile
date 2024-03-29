SHELL := /usr/bin/env bash

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
	@make -qp | awk -v RS="" '!/Not a target/{if ($$0 ~ /^[^ %]+:/) {split($$0, A, ":"); print A[1];}}' | sort -u | grep -v ".PHONY"

all: autogen_dma_mem create synth impl

init:
	git submodule update --init

reg:
	$(TIMECMD) cd regmap && make

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
	@time Hog/Do CREATE $(patsubst create_%,%,$@)                                          $(COLORIZE)

$(PROJECT_LIST):
	@echo -------------------------------------------------------------------------------- $(COLORIZE)
	@echo Launching Hog Workflow $@                                                        $(COLORIZE)
	@echo -------------------------------------------------------------------------------- $(COLORIZE)
	@time Hog/Do WORKFLOW $@                                                               $(COLORIZE)

$(OPEN_LIST):
	vivado Projects/$(patsubst open_%,%,$@)/$(patsubst open_%,%,$@).xpr &

fpgaman_bin:
	cd util; python3 create_fpga_manager_bin.py

autogen_dma_mem:
	python3 util/autogen_res_mem.py

clean:
	rm -rf Projects/
