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

This quick-deploy setup will automatically make new one but will not remove old ones. You can remove unneeded entries like this:

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

## Creating an Image

### Using Docker to create an image
> Note: Docker seems to have issues when using `losetup`. Before running the docker image you should note down all loopback devices, you can do this with `losetup -l`. The container should handle this type of failure, but in the case that it doesn't, you can clean up from a failed build attempt with the following: Remove any images (`rm img*`) and any mountpoints if they still exist (`rm mnt*`). You should then detach any ***new*** loopback devices (`losetup -d /dev/loopX`). You can again find current loopback devices with `losetup -l`.

#### Building the build environment
Docker is provided here as a means of allowing this script to be run across Linux distributions. A `Dockerfile` is provided here to allow the quick setup of an Archlinux-based environment. To build the docker image you can run the following command in this directory:

```bash
docker build -t quickdeploy:local .
```

### Importing a docker image release

If you would rather import the image than build it yourself, you can find premade images on [the release page](https://github.com/desert0n1pX/bigscreen-quickdeploy/releases).

After downloading the tar archive you can import the image with:

```bash
docker image load -i /path/to/quickdeploy-docker-v1.1.0.tar
```

#### Making the final image

After the docker image has successfully been made you can now use it to run the script to build a ready-to-flash Archlinux image for Plasma Bigscreen. The container will look for a config file named `quickdeploy-docker.conf` in the volume mounted at `/build`. In the command below the current directory `.` is specified.

> Note: During testing the build seems to fail twice before successfully producing an image.

```bash
docker run --privileged --rm -v .:/build quickdeploy:local
```

> Note: If you imported the image the command will look something like this

```bash
docker run --privileged --rm -v .:/build quickdeploy:v1.1.0
```

---

### Using an existing arch system to create an image
If you have an existing arch system you can use it to build a ready-to-flash Archlinux image for Plasma Bigscreen without the troubles of docker.

#### Environment setup

Make sure you have the following packages:

```
core/dosfstools core/which extra/arch-install-scripts extra/imagemagick extra/librsvg extra/lsof extra/parted extra/qemu-img extra/wget
```

#### Making the final image

Run the script as root to build an image with default settings. You can either use a config file or command line switches, use `sh deploy.sh --help` for more info.

> Warning: On an existing system avoid using the `-d, --device` flag or the `DEVICE` config option unless you intend to install to a storage device connected to your system.

```
sh deploy.sh
```

## Installing With an Image

Once the image is produced (Default name `plasmabigscreen.img`) you can flash it directly to the primary storage medium of the device you want to install too much like you would do to a Raspberry Pi.

You can use tools like dd to do this:
```bash
dd if=/path/to/image.img of=/path/to/target bs=4M oflag=direct status=progress
```

or you can also use graphical tools like Balena Etcher.

## Using the arch installation medium

If you'd prefer to use an arch-iso to directly install the new system you can also use this script to speed up the process.

### Getting ready

You should obtain an arch-iso image and boot it with the new system. For more information you can reference the [Archlinux Website](https://archlinux.org/download/).

After booting the iso you should install the dependencies:
```
root@archiso ~# pacman -Syy git imagemagick lsof librsvg qemu-img
```

You can then clone this repo:
```
git clone https://github.com/desert0n1pX/bigscreen-quickdeploy.git
```

#### Installing
You can now enter the repo and use the script's `--device` argument or config entry to specify the device you want to install to. You should also use the `-r` or `--no-zero` argument. It might look something like this:

```
sh deploy.sh -r -d /dev/sda
```

or


```
sh deploy.sh -r -d /dev/nvme0n1
```

## After Installation Notes

These are some things you should know after performing an installation.

### First Boot
At first boot you will be presented with a black screen and a TTY. The image will automatically expand to fill the rest of the device it was installed to. It will then setup a swapfile and configure the system for the next boot. When the process is complete the system will automatically restart.

### Application Menu

Plasma Bigscreen seems to hide applications that run in the terminal. If you want to make your own application launchers you should set `Terminal=false` or "Run in terminal" to false and set the program as "/usr/bin/konsole -e /path/to/script" or `Exec=/usr/bin/konsole -e /path/to/script`. This image provides the following application shortcuts:

```
Update System (Update the entire system then reboot)
Toggle Virtual Keyboard (Toggle showing virtual on touch/pen input or any input method)
```

### Custom Scripts
There are a couple of scripts that may be useful:

> You may consider binding the command `/opt/mediabox-scripts/setvtkbd.sh toggle` to a key/button if you are using a remote. Both scripts have an application shortcut that can be searched for.

```
/opt/mediabox-scripts/setvtkbd.sh: Control when the virtual keyboard activates
/opt/mediabox-scripts/updater.sh:  Update the system then reboot
```

### Custom Services
Should you choose to use input-remapper, there is a custom service that looks for new devices every 10 seconds. If a new device is detected a service (`input-remapper-loader.service`) will prompt input-remapper to load all profiles that are configured to autoload.

### Software

> Warning: The AUR is user controlled, it should be used with caution. You can read more about it on the [Arch Wiki](https://wiki.archlinux.org/title/AUR).

This image is configured to use the [Chaotic AUR](https://aur.chaotic.cx/) for easy installations without having to worry about compiling software. However, you can still install an AUR helper and use the normal AUR.

Packagekit is also installed allowing you to use the `Discover` appstore to manage both system and flatpak packages, although it is recommended that you only use it for flatpaks.

Gear Lever is also installed allowing you to "install" appimages and automatically keep them up-to-date given that `topgrade` or the updater script is run.

## Other Notes

### genfstab
The normal `genfstab` doesn't work in docker so this repo contains a patch for it.