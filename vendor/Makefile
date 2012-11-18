#-*- mode:makefile-gmake; -*-

all: | brews
	$(MAKE) grue
	$(MAKE) s3g

## s3g setup
s3g:
	@echo "TODO: Build s3g"

## Grue build
grue: Miracle-Grue/bin/miracle_grue
Miracle-Grue/bin/miracle_grue:
	cd Miracle-Grue && scons

s3g: s3g/virtualenv/bin/activate
s3g/virtualenv/bin/activate:
	cd s3g && ./setup.sh

## System
brews:
	@brew install avrdude || echo "AVRDude already brew installed [or failed]"
	@brew install scons || echo "scons already brew installed [or failed]"

.PHONY: all brews grue s3g
