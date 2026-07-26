#!/bin/bash

mkdir -p output/images/spinner output/images/16bit/spinner

for i in $(seq 0 10 360)
do
    echo Angle $i
    magick -background none "busywidget.svgz" -distort SRT "$i" -resize 28 "output/images/spinner${i}.png"
    magick -background none "busywidget.svgz" -colors 256 -distort SRT "$i" -resize 28 "output/images/16bit/spinner${i}.png"
done

magick -background none "logo-big.svg" -resize 128 "output/images/bigscreen.logo.png"
magick -background none "logo-big.svg" -colors 256 -resize 128 "output/images/16bit/bigscreen.logo.png"

magick -background none logo-big.svg output/logo-big.png
magick "../bigscreen/preview.png" -draw "rectangle 256,136,384,264" -draw "image over 256,136 128,128 output/logo-big.png" output/preview.png