#!/bin/bash

## Countdown for shutdown/reboot
COUNTDOWN=10

echo "Using updater script."

topgrade

echo "Topgrade exited with $?"

if [ "$?" = "0" ]
then
	for i in $(seq $COUNTDOWN -1 1)
	do
		echo "Rebooting in ${i}..."
		sleep 1
	done
	shutdown -r now

else
	echo "Topgrade exited with an error, manual intervention might be required."

fi

