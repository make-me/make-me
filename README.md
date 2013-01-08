# MakeMe [![Build Status](https://travis-ci.org/make-me/make-me.png)](https://travis-ci.org/make-me/make-me)
A pipeline for taking your [MakerBot Replicator 2](https://store.makerbot.com/replicator2.html)
to the next level of awesome. Embrace the meatspace!

## Support

At the moment, this only works on **OS X 10.8+** and ships with a binary
compiled for this platform. However, the binary relates to make-me's
photo function, so some customization should enable other systems.

[Homebrew](http://mxcl.github.com/homebrew/) is required for the
bootstrap to run. If you don't have it, go get it. We'll still be here.

## Setup

We've made it as easy as possible to get started with make-me. It's easy
as...

    $ git clone https://github.com/make-me/make-me.git
    $ cd make-me
    $ script/bootstrap

## CLI Interface

Your printer can now be operated using make-me's command line tools.
Hooray! Make-me comes with some STL files so you can test the basic
operations of the toolchain:

    $ ls ./data
    Mr_Jaws.stl

You can also use external models from places like
[Thingiverse](http://www.thingiverse.com):

    # Download Mr.Jaws from http://www.thingiverse.com/thing:14702
    $ curl -L http://www.thingiverse.com/download:48479 > data/jaws.stl

Plug the MakerBot printer into the computer with the USB cable.

To print a model, invoke `make` with the path to the model, leaving off the
extension:

    $ make data/jaws

This is enough to get most things printed without tweaking, but
make-me can adjust print parameters for you:

### Slicer config

    $ make GRUE_CONFIG=default path/to/model

`GRUE_CONFIG=name` controls the slicer config to use. These are stored in
`./config/` in the project root and two configs are included.

* `default` - The default configuration, it's used if no config is specified.
* `support` - A slicer configuration that generates support structures
for the model. This is particularly awesome for abstract shapes.

### Print quality

    $ make QUALITY=low path/to/model

`QUALITY=(low|medium|high)` controls the quality of the print by altering the
line height of object layers.

* high   -- 0.1mm
* medium -- 0.27mm
* low    -- 0.34mm

### Print density

    $ make DENSITY=0.1 path/to/model

`DENSITY=<percentage>` controls the infill percentage of the print. The default
setting is `0.05`

### Normalization and packing

Make-me ships with
[stltwalker](https://github.com/sshirokov/stltwalker), which is used to normalize
input models and offer advanced functionality. But, stltwalker can also be used
standalone as part of a manual print.

Help for the version of `stltwalker` bundled with make-me can be found
at:

    $ vendor/stltwalker/stltwalker -h

Stltwalker can be used to composite multiple objects or multiple copies of a
single object into a single print:

    $ vendor/stltwalker/stltwalker -p data/object_a.stl data/object_b.stl data/object_b.stl -o data/out.stl
    # [.. stltwalker output ..]
    $ make QUALITY=low data/out

## HTTP API

Yes, we shipped make-me with an API. You deserve it.
You can fire up the web app by running:

    script/server

Now you can POST a URL to the server and it'll start printing. The default HTTP
auth credentials are *hubot* **:** *isalive*. They're  controlled with the
`MAKE_ME_USERNAME` and `MAKE_ME_PASSWORD` environment variables.

The maximum dimensions of the print can be specified with the `$MAKE_ME_MAX_X`, `$MAKE_ME_MAX_Y` and
`$MAKE_ME_MAX_Z` environment variables. The defaults are configured for the MakerBot Replicator 2.


    $ curl -i http://hubot:isalive@localhost:9393/print               \
           -d '{"url": "http://www.thingiverse.com/download:48876"}'

To manually unlock the printer with `curl` you can either issue a DELETE request
or a POST request with `_method=DELETE` as a parameter:

    # These are equivalent
    $ curl -i -X DELETE http://hubot:isalive@localhost:9393/lock
    $ curl -i -d '_method=DELETE' http://hubot:isalive@localhost:9393/lock

### `GET /` -- HTML "Front page"

    $ open http://localhost:9393/

The front page is a human-friendly view of the current print, the state of the
lock, the progress and the complete log of the print. It's awesome, and
you might enjoy it.

### `POST /print` -- Print an object

    $ curl -i -d '{"url": ["http://www.thingiverse.com/download:48876"],  \
                   "count": 1,                                            \
                   "scale": 1.0,                                          \
                   "quality": "low",                                      \
                   "density": 0.05,                                       \
                   "config": "default"}'                                  \
           http://hubot:isalive@localhost:9393/print

The parameters in the JSON object are

* `url`     - Either a String or an Array of Strings that are URLs of **.stl** objects. **Required**
* `quality` - The quality of the print, defined by line height. Can be "high", "medium" or "low". Default: "medium", **Optional**
* `count`   - The number of times to print all the given objects. Default: 1, **Optional**
* `scale`   - The scaling factor of the print. Default 1.0, **Optional**
* `density` - The infill density of the object. From 0.0 to 1.0. Default: 0.05, **Optional**
* `config`  - The Miracle-Grue config to use during slicing Default: "default", **Optional**

Returns `HTTP 200 OK` when the print appears to have begun successfully.

Returns `HTTP 409 CONFLICT` when the given STL models cannot be normalized or
transformed.

Returns `HTTP 423 LOCKED` when the print cannot be started because the printer
is locked.


### `GET /lock` -- Lock status

    $ curl -i http://hubot:isalive@localhost:9393/lock

Returns `HTTP 200 OK` when the lock is clear.

Returns `HTTP 423 LOCKED` when the printer is locked, returns the lock contents
as JSON.

### `GET /photo` -- Take a snapshot of the printer

    $ open http://localhost:9393/photo

When successful will return `HTTP 302 FOUND` with a permanent location of a
picture from the camera. You're now a 3D printing paparazzo!

A different camera can be selected by passing the `?camera=N` parameter
with an integer argument. The count starts, and defaults to 0.

### `DELETE /lock` -- Unlock the printer

    # These are equivalent
    $ curl -i -X DELETE http://hubot:isalive@localhost:9393/lock
    $ curl -i -d '_method=DELETE' http://hubot:isalive@localhost:9393/lock

Unlocks the printer. A printer can only be unlocked when no job is active.

Returns `HTTP 200 OK` if the lock was successfully cleared.

Returns `HTTP 404 NOT FOUND` if the lock is free.

## Hubot Compatibility

[Hubot](http://hubot.github.com/) can now make things for you. If you
include our
[hubot-script](https://github.com/github/hubot-scripts/blob/master/src/scripts/make_me.coffee),
you'll be able to use your 3D printer through Campfire. Our script
comes preconfigured for localhost:9292, but this can be altered for your
own network preferences. This may seem like the origins of Skynet, but
we assure you that it's not.

## How can I contribute?

Contributing is easy. Fork this repo, hack away, and submit your
[pull request](https://help.github.com/articles/using-pull-requests).
Make Me is currently maintained by [@skalnik](http://github.com/skalnik/) and
[@sshirokov](http://github.com/sshirokov).

Most importantly, go print things! We hope make-me can remove any
obstacles you may be facing in your 3D printing adventures. Living
in the future shouldn't be annoying.
