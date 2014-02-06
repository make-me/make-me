#-*- mode:makefile-gmake; -*-

all: | brews
	$(MAKE) cura
	$(MAKE) s3g
	make -C stltwalker

## Cura build
cura: cura/CuraEngine
cura/CuraEngine:
	cd cura && make

s3g: s3g/virtualenv/bin/activate
s3g/virtualenv/bin/activate:
	cd s3g && ./setup.sh

## System
brews:
	@brew install avrdude || echo "AVRDude already brew installed [or failed]"
	@brew install scons || echo "scons already brew installed [or failed]"

.PHONY: all brews grue s3g
