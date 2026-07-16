#!/bin/bash

# Variables
SWAPFILE=/swapfile


# Main program
# Parameters passed from cli
main() {

    # Warning
    bash -c 'while true ; do wall "Do not poweroff! Building boot images... Please wait for automatic system reboot..." ; sleep 5 ; done' &

    # Expand filesystem
    adjRootSize

    # Setup swap stuff
    setupSwap
    setupResume

    systemctl disable auto-storage-setup.service
    systemctl enable  sddm.service
    (efibootmgr | grep "PlasmaBigscreen Fallback" )                        || efibootmgr --create --disk "$(getRootParentDev)" --part 1 --loader "\EFI\PlasmaBigscreen\arch-linux-lts-fallback.efi" --label "PlasmaBigscreen Fallback" --unicode
    (efibootmgr | grep -v "PlasmaBigscreen Fallback" | "PlasmaBigscreen" ) || efibootmgr --create --disk "$(getRootParentDev)" --part 1 --loader "\EFI\PlasmaBigscreen\arch-linux-lts.efi"          --label "PlasmaBigscreen"          --unicode # since this was the last added, it should be default
    rm -rf /efi/EFI/BOOT # This was a one time UKI build only for first boot
    rm /etc/systemd/system/auto-storage-setup.service

    reboot
}

# Expand root to full device
#
# No Parameters
# No return
adjRootSize() {
    # Grow partition
    growpart "$(getRootParentDev)" 2

    # ResizeFS
    resize2fs "$(getRootDev)"
}

# Setup swap
#
# No Parameters
# No return
setupSwap() {
    mkswap -U clear --size "$(getMem)" --file "${SWAPFILE}"

    (grep "${SWAPFILE}" /etc/fstab 2>&1 > /dev/null) || cat << EOF >> /etc/fstab

# Swapfile created automatically after first boot
${SWAPFILE}           none        swap        defaults        0   0

EOF

    swapon "${SWAPFILE}"
}

# Setup swap resume
#
# No Parameters
# No return
setupResume() {
    # Prevent multiple appends
    (grep "resume_offset" /boot/cmdline/default 2>&1 > /dev/null) || echo -n " resume=$(getRootDev) resume_offset=$(getSwOffset)" >> /boot/cmdline/default

    mkinitcpio -P
}


# Get root device
# Return example: `/dev/sda2`
#
# No parameters
# Return: Root device and partition
getRootDev() {
    mount | grep " on / type " | awk '{ print $1}'
}

# Get root parent device
# Return example: `/dev/sda`
#
# No parameters
# Return: Root device
getRootParentDev() {
    echo -n "/dev/$(lsblk -no pkname "$(getRootDev)" | tail -n1)"
}

# Get total mem
# Return example: `63570616`
#
# No parameters
# Return: Memory in kilobytes
getMem() {
    free | grep Mem: | awk '{ print $2}'
}

# Get swap offset
# Return example: `4161536`
#
# No parameters
# Return: Swapfile offsets in blocks (i think)
getSwOffset() {
    filefrag -v "${SWAPFILE}" | awk '$1=="0:" {print substr($4, 1, length($4)-2)}'
}

main $@
