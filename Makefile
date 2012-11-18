#-*- mode:makefile-gmake; -*-
ROOT = $(shell pwd)
USB ?= $(shell ls /dev/ | grep tty.usbmodem | head -1)

## Apps
GRUE ?= bin/miracle_grue
PRINT ?= python print_gcode_file.py -m "The Replicator 2" -p /dev/$(USB) -f

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
	(cd vendor/s3g; . virtualenv/bin/activate; cd examples; $(PRINT) $(realpath $^))


%.gcode: %.stl
	@echo "Building gcode: At[$@] In[$^]"
	(cd vendor/Miracle-Grue/; $(GRUE) -s /dev/null -e /dev/null -o "$(realpath $(dir $@))/$(notdir $@)" "$(realpath $^)")

## Plumbing
init:
	@echo "=> Loading submodules"
	git submodule update --init --recursive
	@echo "=> Building deps"
	$(MAKE) -C vendor


## Main
.DEFAULT_GOAL = help
.PHONY: help init

help:
	@echo "Usage:               "
	@echo " $$ make name/of/thing"
