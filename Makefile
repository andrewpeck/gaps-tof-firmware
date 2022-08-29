SHELL := /bin/bash

.PHONY: create synth impl reg init

NJOBS := 4

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

PROJECT_LIST = $(patsubst %/,%,$(patsubst Top/%,%,$(dir $(dir $(shell find Top/ -name hog.conf)))))
CREATE_LIST = $(addprefix create_,$(PROJECT_LIST))
IMPL_LIST = $(addprefix impl_,$(PROJECT_LIST))
OPEN_LIST = $(addprefix open_,$(PROJECT_LIST))
UPDATE_LIST = $(addprefix update_,$(PROJECT_LIST))

$(CREATE_LIST):
	@echo -------------------------------------------------------------------------------- $(COLORIZE)
	@echo Creating Project $(patsubst create_%,%,$@)                                       $(COLORIZE)
	@echo -------------------------------------------------------------------------------- $(COLORIZE)
	@time Hog/CreateProject.sh $(patsubst create_%,%,$@)                                   $(COLORIZE)

$(IMPL_LIST):
	@echo -------------------------------------------------------------------------------- $(COLORIZE)
	@echo Launching Hog Workflow $(patsubst impl_%,%,$@) with njobs = $(NJOBS)             $(COLORIZE)
	@echo -------------------------------------------------------------------------------- $(COLORIZE)
	@time Hog/LaunchWorkflow.sh $(patsubst impl_%,%,$@) -njobs $(NJOBS)                    $(COLORIZE)

$(UPDATE_LIST): config

	@{ \
		set -e; \
			\
		`# OPTOHYBRID ` ; \
		if [[ $@ == *"oh_"* ]]; then \
			if [[ $@ == *"ge21"* ]] ; then \
				system="ge21" ; \
				type="" ; \
			elif [[ $@ == *"ge11"* ]] ; then \
				system="ge11" ; \
				type="-l long" ; \
			else \
				system="unknown" ; \
				type="" ; \
			fi ; \
			\
			mkdir -p address_table/gem/generated/oh_$$system/ && \
			cp address_table/gem/optohybrid_registers.xml address_table/gem/generated/oh_$$system/optohybrid_registers.xml && \
			python scripts/boards/optohybrid/update_xml.py -s $$system $$type -x address_table/gem/generated/oh_$$system/optohybrid_registers.xml && \
			cd regtools && python generate_registers.py -p generated/oh_$$system/ oh \
			\
		`# BACKEND ` ; \
			\
		else \
			`# GEM ` ; \
			if [[ $@ == *"me0"* ]] || [[ $@ == *"ge21"* ]] || [[ $@ == *"ge11"* ]] ; then \
				system="gem"; \
				module="gem_amc"; \
			`# CSC ` ; \
			elif [[ $@ == *"csc"* ]]; then \
				system="csc"; \
				module="csc_fed"; \
			`# unknown` ; \
			else \
				system="unknown"; \
			fi ; \
			\
			cd address_table/$$system && python generate_xml.py ; cd - ;\
			cd regtools && python generate_registers.py -p generated/$(patsubst update_%,%,$@)/ $$module ; cd - ;\
		fi ; \
	}

$(OPEN_LIST):
	vivado Projects/$(patsubst open_%,%,$@)/$(patsubst open_%,%,$@).xpr &

init:
	git submodule update --init

reg:
	cd regmap && make

fpgaman_bin:
	cd util; python3 create_fpga_manager_bin.py

autogen_dma_mem:
	python3 util/autogen_res_mem.py

clean:
	rm -rf Projects/
