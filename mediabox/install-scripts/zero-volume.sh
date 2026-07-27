#!/bin/bash

# $1: mediabox location
# $2: device

if [ -z "$2" ]
then
    echo "Cant continue: no device specified"
fi

BINARY="$1/mediabox/lib/zerofree-1.1.1/zerofree"

if [ ! -f "$BINARY" ] || [ ! -x "$BINARY" ]
then
    echo "Zerofree not found, retrieving source and building..."

    mkdir "$1/mediabox/lib"

    wget -O "$1/mediabox/lib/zerofree-1.1.1.tgz" https://frippery.org/uml/zerofree-1.1.1.tgz

    echo "956bc861b55ba0a2b7593c58d32339dab1a0e7da6ea2b813d27c80f08b723867  $1/mediabox/lib/zerofree-1.1.1.tgz" | sha256sum -c || exit 1

    (cd "$1/mediabox/lib" && tar xzvf zerofree-1.1.1.tgz)

    (cd "$1/mediabox/lib/zerofree-1.1.1" && make)
fi

if [ "$2" = "BUILD" ]
then
    echo "Only run for build"
    exit 0
fi

$BINARY -v $2