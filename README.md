# Bigscreen Quick-Deploy

This repository contains scripts for the rapid deployment of Archlinux with plasma-bigscreen. Its intended for devices like the Intel NUC but can be used on any UEFI capable x86_64 computer.

## Getting Started

Before installing to any device I recommend that you remove any previous EFI boot entries. Although this is optional this ensures that only the relevant entries exist. You can do this with the `efibootmgr` tool included in arch-iso. You can list entries with the following:

```bash
efibootmgr 
```

You should see something that looks like this:

```
BootCurrent: 0000
Timeout: 0 seconds
BootOrder: 0000,0001
Boot0000* rEFInd Boot Manager   HD(1,GPT,5c26141e-e813-4631-979f-cc376cc22abd)/\EFI\refind\refind_x64.efi
Boot0001* Windows Boot Manager  HD(1,GPT,1889f9b2-11e7-44fa-9d86-3e88566503fa)/\EFI\Microsoft\Boot\bootmgfw.efi
Boot2001* EFI USB Device        RC
Boot2002* EFI DVD/CDROM RC
Boot2003* EFI Network   RC
```

This quick-deploy setup will automatically make new one but will not remove old ones. You can remove needed entries like this:

> Note: You should avoid removing entries like "Setup" or "Diagnostics" as these are options for managing your firmware at boot time.

```
efibootmgr -B -b 0000 # Delete rEFInd entry
efibootmgr -B -b 0001 # Delete Windows entry
```

## Installation

There are a few ways to perform an installation:
 - Create an image using docker and flash it to the device's primary drive
 - Create an image using an existing arch system and flash it to the device's primary drive
 - Use an arch-iso to install it directly to the other device

 ### Using Docker to create an image
 > Note: Docker seems to have issues when using `losetup`. Before running the docker image you should note down all loopback devices, you can do this with `losetup -l`. To clean up from a failed build attempt, remove any images (`rm img*`) and any mountpoints if they still exist (`rm mnt*`). You should then detach any new loopback devices (`losetup -d /dev/loopX`). You can again find current loopback devices with `losetup -l`.

 #### Building the build environment
Docker is provided here as a means of allowing this script to be run across Linux distributions. A `Dockerfile` is provided here to allow the quick setup of an Archlinux-based environment. To build the docker image you can run the following command in this directory:

```bash
docker build -t quickdeploy:local .
```

#### Making the final image

After the docker image has successfully been made you can now use it to run the script to build a ready-to-flash Archlinux image for Plasma Bigscreen. The container will look for a config file named `quickdeploy-docker.conf` in the volume mounted at `/build`. In the command below the current directory `.` is specified.

> Note: During testing the build seems to fail twice before successfully producing an image.

```bash
docker run --privileged --rm -v .:/build quickdeploy:local
```

Once the image is produced (Default name `plasmabigscreen.img`) you can flash it directly to the primary storage medium of the device you want to install too much like you would do to a Raspberry Pi.

### Using an existing arch system to create an image
If you have an existing arch system you can use it to build a ready-to-flash Archlinux image for Plasma Bigscreen without the troubles of docker.

#### Environment setup

Make sure you have the following packages:

```
core/which core/dosfstools extra/lsof extra/parted extra/qemu-img extra/arch-install-scripts
```

#### Making the final image

Run the script as root to build an image with default settings. You can either use a config file or command line switches, use `sh deploy.sh --help` for more info.

> Warning: On an existing system avoid using the `-d, --device` flag or the `DEVICE` config option unless you intend to install to a storage device connected to your system.

```
sh deploy.sh
```

Again, once the image is produced (Default name `plasmabigscreen.img`) you can flash it directly to the primary storage medium of the device you want to install too much like you would do to a Raspberry Pi.

### Using the arch installation medium

If you'd prefer to use an arch-iso to directly install the new system you can also use this script to speed up the process.

#### Getting ready

You should obtain an arch-iso image and boot it with the new system. For more information you can reference the [Archlinux Website](https://archlinux.org/download/).

After booting the iso you should install the dependencies:
```
root@archiso ~# pacman -Syy qemu-img git
```

You can then clone this repo:
```
git clone https://github.com/desert0n1pX/bigscreen-quickdeploy.git
```

#### Installing
You can now enter the repo and use the script's `--device` argument or config entry to specify the device you want to install to:

```
sh deploy.sh -d /dev/sda
```

or


```
sh deploy.sh -d /dev/nvme0n1
```
