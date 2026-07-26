#!/bin/bash
# $1: Source
# $2: Mount

# Generate plymouth assets
"$1/mediabox/plymouth/image-generator/generate-images.sh" "$1/mediabox/plymouth/image-generator/" "$2"

# Make theme directory
mkdir "$2/usr/share/plymouth/themes/bigscreen"

# Copy theme text
cp "$2/usr/share/plymouth/themes/breeze/breeze.grub" "$2/usr/share/plymouth/themes/bigscreen/bigscreen.grub"
cp "$1/mediabox/plymouth/bigscreen/bigscreen.plymouth" "$2/usr/share/plymouth/themes/bigscreen/bigscreen.plymouth"
cp "$2/usr/share/plymouth/themes/breeze/breeze.script" "$2/usr/share/plymouth/themes/bigscreen/bigscreen.script"

# Copy theme assets
cp -r "$1/mediabox/plymouth/image-generator/output/*" "$2/usr/share/plymouth/themes/bigscreen/"

# Patch or change
sed -i 's/plasma.logo.png/bigscreen.logo.png/g' "$2/usr/share/plymouth/themes/bigscreen/bigscreen.script"