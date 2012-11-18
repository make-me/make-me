## A pipeline for getting things 3D printed.


## Setup

Clone this repo

    git@github.com:github/print_me.git

Download a `*.stl` file and place it in `data` directory.

Plug the makerbot printer into the computer.

To print a model, invoke `make` with the model name,
including `data` but without the extension.

    $ make data/Mr_Jaws

If something breaks, panic, and remember this isn't even Alpha.