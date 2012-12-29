## A pipeline for getting things 3D printed.

## Support

At the moment, this only works on **OS X 10.8+** and ships with some binaries
compiled for this platform. This is not ideal.

## Setup

    $ git clone https://github.com/make-me/make-me.git
	$ cd make-me
	$ make init

## CLI Interface

The printer can be operated using command line tools within this repository.
The project comes with some STL files to use to test the basic operations
of the toolchain

	$ ls ./data
    Mr_Jaws.stl

You can also use external models from places like [Thingiverse](http://www.thingiverse.com)

    # Download Mr.Jaws from http://www.thingiverse.com/thing:14702
    $ curl -F http://www.thingiverse.com/download:48479 > data/jaws.stl

Plug the makerbot printer into the computer with the USB cable.

To print a model, invoke `make` with the path to the model, leaving
off the extension

    $ make data/jaws

This is enough to get most things printed without much further tweaking, but
several print parameters can be adjusted from the enviornment

### Slicer config

    $ make GRUE_CONFIG=default path/to/model

`GRUE_CONFIG=name` controls the slicer config to use. These are stored in `./config/` in the project root and two configs are included.

* `default` - The default configuration, it's used if no config is specified
* `support` - A slicer configuration that genrates support structures for the model.

### Print quality

    $ make QUALITY=low path/to/model

`QUALITY=(low|medium|high)` controls the quality of the print by altering the line height
of object layers.

* high   -- 0.1mm
* medium -- 0.27mm
* low    -- 0.34mm

### Print density

    $ make DENSITY=0.1 path/to/model

`DENSITY=<percentage>` controls the infil percentage of the print. The default setting is `0.05`

### Normalization and packing.

The make-me distribution ships with a version of the [stltwalker](https://github.com/sshirokov/stltwalker) tool which
is used by the web service described below to offer advanced functionality and to normalize input models but can also
be used standalone as part of a manual print.

Help for the version of `stltwalker` bundled with make-me can be obtained with

    $ vendor/stltwalker/stltwalker -h

The tool can be used to composite multiple objects or multiple copies of a single object
into a single print, as is allowed by the [HTTP API](#http-api)

    $ vendor/stltwalker/stltwalker -p data/object_a.stl data/object_b.stl data/object_b.stl -o data/out.stl
	# [.. stltwalker output ..]
    $ make QUALITY=low data/out

## HTTP API

The service can also be controlled through an HTTP API.
You can launch the web app by simply running

    script/server

Then you can POST a URL to the server and it'll start printing. The default
HTTP auth credentials are *hubot* **:** *isalive*. They can be controlled with the
`MAKE_ME_USERNAME` and `MAKE_ME_PASSWORD` environment variables.

    curl -i http://hubot:isalive@localhost:9393/print               \
         -d '{"url": "http://www.thingiverse.com/download:108313"}'