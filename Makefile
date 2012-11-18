#-*- mode:makefile-gmake; -*-
THING ?= data/Mr_Jaws.stl
USB ?= $(shell ls /dev/ | grep tty.usbmodem | head -1)

##
THING_GCODE = $(patsubst %.stl,%.gcode,$(THING))

## Apps
GRUE ?= echo bin/miracle_grue
PRINT ?= echo python print_gcode_file -m "The Replicator 2" -p $(USB) -f

%: %.gcode
	file $(USB) || { echo "No USB device found"; exit 1; }
	@echo "Printing"
	$(PRINT) $^


%.gcode: %.stl
	@echo "Building gcode"
	$(GRUE) -s /dev/null -e /dev/null -o $@ $^


## Main
.DEFAULT_GOAL = help
.PHONY: help

help:
	@echo "Usage:               "
	@echo " $$ make name/of/thing"
