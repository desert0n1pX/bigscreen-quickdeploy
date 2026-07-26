#!/bin/bash

# $1: device

if [ -z "$1" ]
then
    echo "Cant continue: no device specified"
fi

BINARY="./lib/zerofree-1.1.1/zerofree"

if [ ! -f "$BINARY" ] || [ ! -x "$BINARY" ]
then
    echo "Zerofree not found, retrieving source and building..."

    mkdir lib

    wget -O lib/zerofree-1.1.1.tgz https://frippery.org/uml/zerofree-1.1.1.tgz

    echo "956bc861b55ba0a2b7593c58d32339dab1a0e7da6ea2b813d27c80f08b723867  lib/zerofree-1.1.1.tgz" | sha256sum -c || exit 1

    (cd lib && tar xzvf zerofree-1.1.1.tgz)

    (cd lib/zerofree-1.1.1 && make)
fi

$BINARY -v $1