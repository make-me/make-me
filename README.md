## A pipeline for getting things 3D printed.

## Setup

Clone this repo

    https://github.com/make-me/make-me.git

Download a `*.stl` file and place it in `data` directory.

Plug the makerbot printer into the computer.

To print a model, invoke `make` with the model name,
including `data` but without the extension.

    $ make data/Mr_Jaws

If something breaks, panic, and remember this isn't even Alpha.

## API

You can launch the web app by simply running

    script/server

Then you can POST a URL to the server and it'll start printing. The default
HTTP auth credentials are *hubot* **:** *isalive*. They can be controlled with the
`MAKE_ME_USERNAME` and `MAKE_ME_PASSWORD` environment variables.

    curl -i http://hubot:isalive@localhost:9393/print               \
         -d '{"url": "http://www.thingiverse.com/download:108313"}'
