#!/bin/bash

# $1: Source Directory (should be where this script is)
# $2: mountpoint

set -e
# Check we are in the right place
# Base dir is: /usr/share/plasma/look-and-feel/org.kde.plasma.bigscreen/contents/splash
test -f "$1/generate-images.sh" || exit 1
test -f "$2/usr/share/plasma/look-and-feel/org.kde.plasma.bigscreen/contents/splash/images/busywidget.svgz" || exit 2
test -f "$2/usr/share/plasma/look-and-feel/org.kde.plasma.bigscreen/contents/splash/images/logo-big.svg" || exit 3
test -f "$2/usr/share/plymouth/themes/breeze/preview.png" || exit 4

mkdir -p "$1/output/images/spinner" "$1/output/images/16bit/spinner"

for i in $(seq 0 10 360)
do
    echo Angle $i
    magick -background none "$2/usr/share/plasma/look-and-feel/org.kde.plasma.bigscreen/contents/splash/images/busywidget.svgz" -distort SRT "$i" -resize 28 "$1/output/images/spinner/spinner${i}.png"
    magick -background none "$2/usr/share/plasma/look-and-feel/org.kde.plasma.bigscreen/contents/splash/images/busywidget.svgz" -colors 256 -distort SRT "$i" -resize 28 "$1/output/images/16bit/spinner/spinner${i}.png"
done

magick -background none "$2/usr/share/plasma/look-and-feel/org.kde.plasma.bigscreen/contents/splash/images/logo-big.svg" -resize 196 "$1/output/images/bigscreen.logo.png"
magick -background none "$2/usr/share/plasma/look-and-feel/org.kde.plasma.bigscreen/contents/splash/images/logo-big.svg" -colors 256 -resize 196 "$1/output/images/16bit/bigscreen.logo.png"

magick -background none "$2/usr/share/plasma/look-and-feel/org.kde.plasma.bigscreen/contents/splash/images/logo-big.svg" "$1/output/logo-big.png"
magick "$2/usr/share/plymouth/themes/breeze/preview.png" -draw "rectangle 256,136,384,264" -draw "image over 256,136 128,128 \"$1/output/logo-big.png\"" "$1/output/preview.png"

rm "$1/output/logo-big.png"