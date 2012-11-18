#-*- mode:makefile-gmake; -*-
THING ?= data/Mr_Jaws.stl
USB ?= $(shell ls /dev/ | grep tty.usbmodem | head -1)

##
THING_GCODE = $(patsubst %.stl,%.gcode,$(THING))

## Apps
GRUE ?= echo bin/miracle_grue
PRINT ?= echo python print_gcode_file -m "The Replicator 2" -p /dev/$(USB) -f

%: %.gcode | init
	@[[ -c /dev/$(USB) ]] || { echo "No USB device found"; exit 1; }
	@echo "Printing"
	$(PRINT) $^


%.gcode: %.stl
	@echo "Building gcode"
	$(GRUE) -s /dev/null -e /dev/null -o $@ $^

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
