#!/bin/bash

## Set KDE virtual keyboard mode
## 0: None, 1: Touch and Pen, 2: Always
##
## Arg1: KBD mode in number
## Return: None
setMode() {
	# Not needed as the dbus method saves the config anyway
	#kwriteconfig6 --file kwinrc --group Wayland --key VirtualKeyboardMode "$1"
	qdbus6 org.kde.KWin /VirtualKeyboard org.freedesktop.DBus.Properties.Set org.kde.kwin.VirtualKeyboard mode "$1"

}


## Get KDE virtual keyboard mode
## 0: None, 1: Touch and Pen, 2: Always
##
## Return: KBD mode in number
getMode() {
	kreadconfig6 --file kwinrc --group Wayland --key VirtualKeyboardMode
}


## Toggle KDE mode between 1 and 2
## if mode is 0 or other, set to 2
## if mode is 2, set to 1
##
## Return: None
toggle() {
	if [ "$(getMode)" != "2" ]
	then
		setMode 2
	else
		setMode 1
	fi
	if [ -n "$1" ]
	then
		sleep $1
	fi
}


## Show current status
##
## Return: None
kbdStatus() {
	case "$(getMode)" in
		"0")
			echo "Disabled"
			;;
		"1")
			echo "Off"
			;;
		"2")
			echo "On"
			;;
		*)
			echo "Error, unknown mode."
			exit 2
	esac

}


## Help Page
helpPage() {
cat << EOF
$0 <subcommand>

 on				Set the keyboard to always on
 off			Set the keyboard to activate on
				pen or touch input
 disable		Fully disable the keyboard
 toggle	<sleep>	Toggle the keyboard between
				on and off, sleep <sleep> seconds
				before exiting
 status			Show keyboard status
 help			Show this page
EOF
}

main() {
	case "$1" in
		"on")
			setMode 2
			;;

		"off")
			setMode 1
			;;

		"disable")
			setMode 0
			;;

		"toggle")
			toggle $2
			;;

		"status")
			kbdStatus
			;;

		"help" | "-h" | "--help")
			helpPage
			;;

		*)
			echo "Unknown subcommand. Use option -h for help"
			exit 1
			;;
	esac	
}

main $@
