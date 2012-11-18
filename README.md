## A pipeline for getting things 3D printed.

## Setup

Clone this repo

    https://github.com/github/make_me.git

Download a `*.stl` file and place it in `data` directory.

Plug the makerbot printer into the computer.

To print a model, invoke `make` with the model name,
including `data` but without the extension.

    $ make data/Mr_Jaws

If something breaks, panic, and remember this isn't even Alpha.

## API

You can launch the web app by simply running

    script/server

Then you can POST a URL to the server and it'll start printing.

    curl -v -d "url=http://f.cl.ly/items/111z2j09430c2v3Q2X1z/CuteOcto.stl" \
      localhost:9393/print

