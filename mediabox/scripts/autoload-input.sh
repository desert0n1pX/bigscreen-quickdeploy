#!/bin/bash

TIME=10s
WANTED=hid-\|input

LASTCYCLE=
FOUND=1

while true
do

	#LASTCYCLE="$(sudo timeout ""$TIME"" dmesg --follow-new | grep -iE ""$WANTED"")"
	LASTCYCLE="$(timeout ""$TIME"" dmesg --follow-new | grep -iE ""$WANTED"")"
	if [ -n "$LASTCYCLE" ]
	then
		echo "I think a device was connected, reloading config!"
		input-remapper-control --command autoload
	fi
done
