#-*- mode:makefile-gmake; -*-
ROOT = $(shell pwd)
USB ?= $(shell ls /dev/ | grep tty.usbmodem | head -1)

## Apps
CURA ?= $(ROOT)/vendor/cura/CuraEngine
CURA_CONFIG ?= default
PRINT ?= $(ROOT)/bin/print_gcode -m "The Replicator 2" -p /dev/$(USB) -f

## What are we making?
THING_DIR = $(realpath $(shell dirname $(MAKECMDGOALS)))
THING_NAME = $(notdir $(MAKECMDGOALS))

%: %.gcode | init
ifneq ($(words $(MAKECMDGOALS)), 1)
	@echo "!!!> ERROR:Can only make one thing at a time" >&2
	@exit 1
endif
	@[[ -c /dev/$(USB) ]] || { echo "No USB device found"; exit 1; }
	@echo "Printing"
	(                                       \
		$(PRINT) $(realpath $^) &           \
		echo $$! > $(ROOT)/tmp/print.pid;   \
		wait `cat $(ROOT)/tmp/print.pid` && \
		rm $(ROOT)/tmp/print.pid;           \
	)


%.gcode: %.stl
	@echo "Building gcode: At[$@] In[$^]"
	@(                                                                                             \
		$(CURA) -o "$(realpath $@)" "$(realpath $^)" -c $(ROOT)/config/rep2-$(CURA_CONFIG).cfg &     \
		echo $$! > $(ROOT)/tmp/slice.pid;                                                            \
		wait `cat $(ROOT)/tmp/slice.pid` &&                                                          \
		rm $(ROOT)/tmp/slice.pid;                                                                    \
	)

## Plumbing
init:
	@echo "=> Loading submodules"
	git submodule sync
	git submodule update --init --recursive
	@echo "=> Building deps"
	$(MAKE) -C vendor


## Main
.DEFAULT_GOAL = help
.PHONY: help init sandwich

# Easter egg
sandwich:
	$(MAKE) data/sandwich

help:
	@echo "Usage:               "
	@echo " $$ make name/of/thing"
