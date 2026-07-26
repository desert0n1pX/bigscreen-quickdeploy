#!/bin/bash

set -e

CONV_TYPE="none"
DEVICE="image"
MODE="image"
EFI_SIZE=512M
EXPAND="no"
LOCALE="en_US.UTF-8 UTF-8"
LANG="en_US.UTF-8"
HOSTNAME=mediabox
IMG_NAME=plasmabigscreen.img
PASSWD=plasma
IMG_SIZE=10G
USER=boxuser
SKIP=false
STUPID_UNIX=false
SOURCE="."

### No touch these variables
__MOUNTPOINT="mnt-$(uuidgen)"
__STEPS=0
__STEP_CURR=0
__TMP_IMG="img-$(uuidgen)"
__ROOT="none"
__EFI="none"
__PART2_UUID="none"
__CONFIG=""

#
# Register a step
#
# Args: None
# Return: None
registerStep() {
    __STEPS=$(($__STEPS + 1))
}

#
# Move to next step
#
# Arg*: Current step explanation
# Stdout: Step and message accompanying it
incrementStep() {
    __STEP_CURR=$(($__STEP_CURR + 1))
    echo "Step [$__STEP_CURR/$__STEPS] $@..."
}

#
# Process the arguments from CLI
#
# Arg*: Args passed from CLI
# Return: None
processArgs() {
    while [ -n "$1" ]
    do
        case $1 in
            -c|--convert)
            shift
            CONV_TYPE="$1"
            shift
            ;;
            
            -d|--device)
            shift
            DEVICE="$1"
            MODE="device"
            shift
            ;;

            -e|--efi)
            shift
            EFI_SIZE="$1"
            shift
            ;;

            -f|--config-file)
            shift
            __CONFIG="$1"
            shift
            ;;
            
            -h|--help|help)
            manPage
            exit 0
            ;;

            -k|--skip-verification)
            shift
            SKIP="true"
            ;;

            -l|--locale)
            shift
            LOCALE="$1"
            shift
            ;;
            
            -m|--lang)
            shift
            LANG="$1"
            shift
            ;;
            
            -n|--hostname)
            shift
            HOSTNAME="$1"
            shift
            ;;
            
            -o|--out)
            shift
            IMG_NAME="$1"
            shift
            ;;

            -p|--password)
            shift
            PASSWD="$1"
            shift
            ;;
            
            --password-stdin)
            shift
            echo "Enter the new password for this image..."
            read -s __PASS1
            echo "Enter the new password for this image again..."
            read -s __PASS2
            if [ "$__PASS1" != "$__PASS2" ]
            then
                echo "Error: The passwords do not match!"
                exit 2
            fi
            PASSWD="$__PASS1"
            ;;
            
            -s|--size)
            shift
            IMG_SIZE="$1"
            shift
            ;;

            --stupid-unix)
            shift
            STUPID_UNIX=true
            ;;

            -t|--path)
            shift
            SOURCE="$1"
            shift
            ;;
            
            -u|--user)
            shift
            USER="$1"
            shift
            ;;
            
            -x|--expand)
            shift
            EXPAND="$1"
            shift
            ;;
            
            *)
            echo "Error, unknown argument! Use \"-h\" for help."
            exit 1
            ;;
        esac
    done
}


# Set a configured variable
#
# Arg1: varname
# Arg2: key
# Return: None
setConfig() {
    case "$1" in
        CONVERT)
        CONV_TYPE="$2"
        ;;
        
        DEVICE)
        DEVICE="$2"
        MODE="device"
        ;;

        EFI_SIZE)
        EFI_SIZE="$2"
        ;;

        SKIP_DESTRUCTION_WARNING)
        SKIP=true
        ;;

        LOCALE)
        LOCALE="$2"
        ;;
        
        LANG)
        LANG="$2"
        ;;
        
        HOSTNAME)
        HOSTNAME="$2"
        ;;
        
        OUTPUT_NAME)
        IMG_NAME="$2"
        ;;

        PASSWORD)
        PASSWD="$2"
        ;;
        
        IMAGE_SIZE)
        IMG_SIZE="$2"
        ;;
        
        USER)
        USER="$2"
        ;;
        
        EXPAND_IMAGE)
        EXPAND="$2"
        ;;

        SOURCE)
        SOURCE="$2"
        ;;

        STUPID_UNIX)
        STUPID_UNIX="$2"
        ;;

        *)
        return 0
        ;;
    esac
}

# Read config from a file
#
# Arg1: File
# Return: None
readConfig(){
    for i in $(seq 0 "$(wc -l ""$1"" | awk '{print $1}')")
    do
        i=$((i+1))
        __THIS_LINE=$(cat "$1" | head -n "$i" | tail -n 1)
        __KEY="$(echo -n $__THIS_LINE | awk 'BEGIN { FS="=" } ; { print $1 }')"
        __VAL="$(echo -n $__THIS_LINE | awk 'BEGIN { FS="=" } ; { print $2 }')"

        setConfig "$__KEY" "$__VAL"
    done
}

#
# Show a summary of our configuration
#
# Args: None
# Return: None
registerStep
showOpts() {
    cat << EOF
CONV_TYPE=${CONV_TYPE}
DEVICE=${DEVICE}
EFI_SIZE=${EFI_SIZE}
EXPAND=${EXPAND}
LOCALE=${LOCALE}
LANG=${LANG}
HOSTNAME=${HOSTNAME}
IMG_NAME=${IMG_NAME}
PASSWD=<REDACTED>
IMG_SIZE=${IMG_SIZE}
USER=${USER}

Is this okay? [y/N]
EOF

if [ "${SKIP}" = "true" ]
then
    return 0
else

    if [ "$(echo -n ""$(pwd)/${__MOUNTPOINT}//etc/pacman.d/gnupg/S.gpg-agent.ssh"" | wc -c)" -gt "108" ]
    then
        echo "WARNING: Total path for the gpg-agent is longer than 108 characters!"
        echo "You will likely need to run this script with \"stupid-unix\" enabled"
    fi

    read RESPONSE
    case "${RESPONSE}" in
        y|Y|yes|YES)
        echo "Ok!"
        ;;

        *)
        echo "User canceled..."
        exit 0
        ;;
    esac

    if [ "$DEVICE" != "image" ]
    then
        echo "You have chosen to install to \"$DEVICE\"."
        echo "THIS WILL COMPLETELY DESTROY ALL EXISTING DATA ON \"$DEVICE\"!"
        echo "To confirm you must type the following phrase in all caps (except device name):"
        echo "i want to destroy all data on $DEVICE"

        read RESPONSE
        case "${RESPONSE}" in
            "I WANT TO DESTROY ALL DATA ON $DEVICE")
            echo "Proceeding with install"
            ;;

            *)
            echo "User canceled..."
            exit 0
            ;;
        esac
    fi
fi

}

#
# Show available arguments
#
# Args: None
# Return: None
manPage(){
    cat << EOF
Usage: $0 [options...] <imgname>

Options:
 -c, --convert <type>       Convert the output to image type
 -d, --device <device>      Rather than create an image, install directly
                            to a device
 -e, --efi <size>           Size of the efi partition in this image in bytes
                            or unit format like 10G
 -f, --config-file <file>   Read a config file (can be overridden by CLI
                            arguments)
 -h, --help                 Show this help page
 -k, --skip-verification    Don't ask if the config is correct before
                            installing THIS WILL DESTROY ALL DATA ON THE
                            TARGET DEVICE WITHOUT CONFORMATION
 -l, --locale <locale>      Locale in the format of "en_US.UTF-8 UTF-8". The
                            space must be included in the argument
 -m, --lang <lang>          Language in the format of "en_US.UTF-8"
 -n, --hostname <name>      Hostname
 -o, --out <file>           Save the image as this file
 -p, --password <password>  Password for user and root
     --password-stdin       Read password from stdin
 -s, --size <size>          Image size in bytes or unit format like 10G
     --stupid-unix          Use a shorter mountpoint name
 -t, --path <path>          Path to the mediabox directory
 -u, --user <username>      Primary username
 -x, --expand [+]<size>     Grow image to/by size
EOF
}

# Check dependancies
#
# Arg*: dependancy list
# Return: none
registerStep
checkDep() {
    __TAINTED=false
    for dep in $@
    do
        if !(which $dep 2>&1 > /dev/null)
        then
            __TAINTED=true
            echo "Dependancy: WARNING: $dep not found"
        fi
    done

    if [ "$__TAINTED" = "true" ]
    then
        exit 1
    fi
}

#########################################################################
#########################################################################
##########################  Image Builder Code ##########################
#########################################################################
#########################################################################

# Create and attatch image
#
# Arg1: Image Path
# Arg2: Image Size
# Return: Device path
registerStep
setupImage() {
    # Create Image
    truncate -s "${2}" "${1}" 
    # Attach image
    losetup -f --show "${1}" # prints dev location
}

# Partition Device
#
# Arg1: Device Path
# Arg2: EFI Size
# Return: None
registerStep
partitionDevice() {
    ### Partitioning, formatting and mounting ###

    awk 'BEGIN { FS = " #" } ; {print $1}' << EOF | sfdisk "${1}" --no-tell-kernel
label: gpt
unit: sectors

size=${2}, type=uefi # Partition 1, EFI System
type=linux # Partition 2, Linux Root
EOF

    # Load new table
    echo "Loading new partition table..."
    partprobe "${1}"

    __EFI="$(sfdisk -d "${1}" | awk '{ print $1 }' | tail -n2 | head -n1)"
    __ROOT="$(sfdisk -d "${1}" | awk '{ print $1 }' | tail -n1 | head -n1)"

}

# Format Device
#
# Arg1: EFI Path
# Arg2: Root Path
# Return: None
registerStep
formatDevice(){
    mkfs.fat -F 32 -n "EFI_SYSTEM" "${1}" > /dev/null
    mkfs.ext4 -L "This Box" "${2}" > /dev/null
    __PART2_UUID="$(blkid ${2} -o export | awk 'BEGIN { FS="=" } ; { if ( $1=="UUID" ) print $2 }')" 
}

# Mount device to mountpoint
#
# Arg1: EFI Path
# Arg2: Root Path
# Arg3: Mountpoint
# Return: none
registerStep
mountDevice() {
    mount "${2}" --mkdir ${3}
    mount "${1}" --mkdir ${3}/efi
}

# Install System
#
# Arg1: Mountpoint
# Return: None
registerStep
installSystem() {
    pacstrap -K "${1}" $(cat "${SOURCE}/mediabox/config/core-packages.list")
    cat "${SOURCE}/mediabox/install-scripts/chaotic.sh" | arch-chroot "${1}" bash

    arch-chroot "${1}" pacman -Sy --noconfirm  --asdeps $(cat "${SOURCE}/mediabox/config/non-default-dependancies.list")
    arch-chroot "${1}" pacman -Sy --noconfirm           $(cat "${SOURCE}/mediabox/config/additional-packages.list")
    rm -rf "${1}/var/cache/pacman/pkg/download-"* || echo "No cached folders to delete..."
    yes | arch-chroot "${1}" pacman -Scc
}

# Configure System
#
# Requires: USER, LOCALE, LANG, HOSTNAME, PASSWD
#
# Arg1: Mountpoint
# Return: None
registerStep
configSystem() {
    echo >> "${1}/etc/fstab"
    genfstab -U "${1}" >> "${1}/etc/fstab"

    arch-chroot "${1}" ln -sf /usr/share/zoneinfo/Universal /etc/localtime
    sed -i "s/#${LOCALE}/${LOCALE}/" "${1}/etc/locale.gen"

    cat << EOF > "${1}/etc/locale.conf"
LANG=${LANG}
EOF

    arch-chroot "${1}" locale-gen

    cat << EOF > "${1}/etc/vconsole.conf"
# This file sets up the console on boot

KEYMAP=us
FONT=default8x16
EOF

    echo -n "${HOSTNAME}" > "${1}/etc/hostname"

    arch-chroot "${1}" useradd -m "${USER}"
    arch-chroot "${1}" usermod -aG wheel,input "${USER}"
    sed -i "s/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/" "${1}/etc/sudoers"

    echo -ne "${PASSWD}\n${PASSWD}\n" | arch-chroot "${1}" passwd
    echo -ne "${PASSWD}\n${PASSWD}\n" | arch-chroot "${1}" passwd "${USER}"

    mkdir "${1}/etc/sddm.conf.d"
    cat << EOF > "${1}/etc/sddm.conf.d/autologin.conf"
[Autologin]
User=${USER}
Session=plasma-bigscreen-wayland
EOF

    arch-chroot "${1}" systemctl enable bluetooth.service NetworkManager.service apparmor.service firewalld.service input-remapper.service

}

# Configure the install of custom files and scripts
#
# Arg1: Mountpoint
# Return: None
registerStep
configCustom() {
    # Copy all scripts
    cp -r "${SOURCE}/mediabox/scripts" "${1}/opt/mediabox-scripts"
    chmod 555 "${1}/opt/mediabox-scripts/"*

    # Copy all service files
    cp "${SOURCE}/mediabox/service/"*.service "${1}/etc/systemd/system/"

    # Copy topgrade config
    cp "${SOURCE}/mediabox/config/topgrade.toml" "${1}/etc/"

    # Copy desktop files
    cp "${SOURCE}/mediabox/config/"*.desktop "${1}/usr/share/applications/"

    # Enable custom services
    arch-chroot "${1}" systemctl enable auto-storage-setup.service input-remapper-loader.service

    # Run other install scripts
    bash "${SOURCE}/mediabox/install-scripts/generate-plymouth-theme.sh" "${SOURCE}" "${1}"
    arch-chroot "${1}" plymouth-set-default-theme bigscreen
}


# Configure Kernel
#
# Arg1: Mountpoint
# Arg2: Root UUID
# Return: None
registerStep
configKernel() {
    ### Remove unused initramfs
    rm "${1}/boot/initramfs-linux-lts.img"

    # Linux preset
    mv "${1}/etc/mkinitcpio.d/linux-lts.preset" "${1}/etc/mkinitcpio.d/linux-lts.default"
    cp "${SOURCE}/mediabox/boot/linux-lts.preset" "${1}/etc/mkinitcpio.d/linux-lts.preset"

    # Initcpio main config
    cp "${SOURCE}/mediabox/boot/default.conf" "${1}/etc/mkinitcpio.conf.d/default.conf"

    # Initcpio fallback config
    cp "${SOURCE}/mediabox/boot/fallback.conf" "${1}/etc/mkinitcpio.conf.d/fallback.conf"

    # Kernel Commandlines
    mkdir "${1}/boot/cmdline"
    echo -n "root=UUID=${2} rw lsm=landlock,lockdown,yama,integrity,apparmor,bpf quiet splash" | tee "${1}/boot/cmdline/default"
    echo -n "root=UUID=${2} rw lsm=landlock,lockdown,yama,integrity,apparmor,bpf break=postmount" | tee "${1}/boot/cmdline/fallback"
}

# Prepare first boot
#
# Arg1: Mountpoint
# Return: None
registerStep
prepareBoot() {
    mkdir "${1}/efi/EFI/PlasmaBigscreen" "${1}/efi/EFI/BOOT" -p
    arch-chroot "${1}" mkinitcpio -P
    cp "${1}/efi/EFI/PlasmaBigscreen/arch-linux-lts.efi" "${1}/efi/EFI/BOOT/BOOTX64.EFI"
}

# Unmount
#
# Arg1: Mountpoint
# Return: None
registerStep
unmountInstall() {

    __HANGING_PID="$(lsof 2>&1 | grep ""$(pwd)/${1}//"" | awk '{ print $2 }' | head -n 1)"
    while [ -n "$__HANGING_PID" ]
    do
        kill "${__HANGING_PID}" || echo "Something went wrong when trying to kill process ${__HANGING_PID} open on the mountpoint"
        sleep 1
        __HANGING_PID="$(lsof 2>&1 | grep ""$(pwd)/${1}//"" | awk '{ print $2 }' | head -n 1)"
    done
    echo "Killed all PIDs using the mount"

    umount    ${1}/efi
    umount -R ${1}
    rm -r  ${1}
    echo "Unmounted image"
}

# Detatch
#
# Arg1: Loop device
# Return: None
registerStep
detatchInstall() {
    losetup -d "${1}"
    echo "Detached \"${1}\""
}

# Resize
#
# Arg1: Raw Image
# Arg1: New size
# Return: None
registerStep
resizeImage() {
    qemu-img resize -f raw "${1}" "${2}"
}

# Convert
#
# Arg1: Raw Image
# Arg2: Image Type
# Arg3: Output Image
# Return: None
registerStep
convertImage() {
    qemu-img convert -f raw "${1}" -O "${2}" "${3}"
}



# Extra steps
registerStep # Finalize image

main () {
    incrementStep "Checking scripts dependancies"
    checkDep arch-chroot awk genfstab losetup magick lsof mkfs.ext4 mkfs.fat pacstrap partprobe qemu-img sed sfdisk truncate wget

    processArgs $@
    if [ -n "$__CONFIG" ]
    then
        readConfig "$__CONFIG"
        processArgs $@
    fi

    if [ "$STUPID_UNIX" = "true" ]
    then
        __MOUNTPOINT=$(uuidgen | head -c 3)
        __TMP_IMG=$(uuidgen | head -c 3)
    fi

    incrementStep "Show config"
    showOpts

    if [ "${MODE}" = "image" ]
    then
        incrementStep "Setup Image"
        DEVICE=$(setupImage "${__TMP_IMG}" "${IMG_SIZE}")
    else
        incrementStep "Setup Image (Skipped)"
    fi
    
    incrementStep "Partitioning"
    partitionDevice "${DEVICE}" "${EFI_SIZE}"

    incrementStep "Formatting"
    formatDevice "$__EFI" "$__ROOT"

    incrementStep "Mounting"
    mountDevice "$__EFI" "$__ROOT" "$__MOUNTPOINT"

    incrementStep "Installing all packages"
    installSystem "$__MOUNTPOINT"

    incrementStep "Configuring system"
    configSystem "$__MOUNTPOINT"

    incrementStep "Configuring Custom Scripts"
    configCustom "$__MOUNTPOINT"

    incrementStep "Configuring kernel and boot process"
    configKernel "$__MOUNTPOINT" "$__PART2_UUID"

    incrementStep "Preparing for first boot"
    prepareBoot "$__MOUNTPOINT"

    incrementStep "Unmounting system"
    unmountInstall "$__MOUNTPOINT"

    if [ "${MODE}" = "image" ]
    then
        incrementStep "Detatch Image"
        detatchInstall "$DEVICE"
    else
        incrementStep "Detatch Image (Skipped)"
    fi

    if [ "${EXPAND}" != "no" ] && [ "${MODE}" = "image" ]
    then
        incrementStep "Expand Image"
        resizeImage "$__TMP_IMG" "$EXPAND"
    else
        incrementStep "Expand Image (Skipped)"
    fi

    if [ "${CONV_TYPE}" != "none" ] && [ "${MODE}" = "image" ]
    then
        incrementStep "Convert Image"
        convertImage "$__TMP_IMG" "$CONV_TYPE" "${__TMP_IMG}.${CONV_TYPE}"
    else
        incrementStep "Convert Image (Skipped)"
    fi

    incrementStep "Finalizing Image/Install"
    if [ "${CONV_TYPE}" != "none" ] && [ "${MODE}" = "image" ]
    then
        mv "${__TMP_IMG}.${CONV_TYPE}" "${IMG_NAME}.${CONV_TYPE}"
        mv "$__TMP_IMG" "$IMG_NAME"
    elif [ "${CONV_TYPE}" = "none" ] && [ "${MODE}" = "image" ]
    then
        mv "$__TMP_IMG" "$IMG_NAME"
    fi
}
main $@