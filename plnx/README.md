# PetaLinux source files and documentation

[[_TOC_]]

## Organization

```
plnx/
  ├── dtsi                : Deprecated, old dts config
  ├── enclustra           : Original source files for Enclustra Mars ZX2 BSP
  ├── project_spec_config : Deprecated, old plnx config
  └── ucla/project-spec   : Source for UCLA DRS4 PetaLinux build
```

## Requirements

* Vivado 2020.1
* PetaLinux 2020.1
* [firmware](../firmware)
  * Built using Hog/Vivado
  * Bitstream generated
  * `.xsa` hardware description file exported

## Build procedure

There are currently two ways to build the kernel and boot images:

 1. *Experimental*: Use custom built UCLA BSP
 2. **RECOMMENDED**: Start from Enclustra BSP and make needed customizations.

### Using UCLA BSP

* Download BSP [here](https://gaps1.astro.ucla.edu/gaps/media/drsdev/ucla_drs4_v2_3_xilinx2020_1.bsp). Note download location
* Create and build project from BSP

```bash
petalinux-create -t project -s /path/to/ucla.bsp
petalinux-configure --get-hw-description=/path/to/.xsa
petalinux-build
petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot --force
```

* Copy following files to `boot` partition of the SD card
  * `BOOT.BIN`
  * `boot.scr`
  * `image.ub`
  
### Using Enclustra BSP

* Download BSP [here](https://github.com/enclustra/Mars_ZX2_EB1_Reference_Design/releases/download/2020.1_v1.1.0/Petalinux_MA-ZX2-10-2I-D9_EB1_SD.bsp)
* Create project from BSP
* In config menu, turn on hardware manager
  * FPGA Manager -> [*] FPGA Manager

```bash
petalinux-create -t project -s /path/to/enclustra.bsp
petalinux-configure --get-hw-description=/path/to/.xsa
```

* Modify device tree files to match those of `ucla/project-spec/meta-user/recipes-bsp/device-tree/files`
* Build

```bash
petalinux-build
petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot --force
```

* Copy following files to `boot` partition of the SD card
  * `BOOT.BIN`
  * `boot.scr`
  * `image.ub`

## SD card

Instructions and tools for creating bootable SD card image with root filesystem.

### Tested parts

| Part number  | Manufacturer | Distributor link                                                                                 | Notes |
|:-------------|:-------------|:-------------------------------------------------------------------------------------------------|:------|
| SDSDQAF-008G | SanDisk      | [amzn](https://www.amzn.com/B07BZ5SY18) |       |

### Formatting

Xilinx has provided documentation for formatting and setting up required partitions. See <https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841655/Prepare+Boot+Medium>. **Important:** above link must be followed to the letter, otherwise the system will not boot.

#### Automated formatting

To speed up this process the `sfdisk` utility can be used. This command should only be used after disk has been erased, following `dd` step in Xilinx doc.

```bash
sudo sfdisk -d /dev/sdX < sd_card/8gb_zynq7_sd.sfdisk
```

At the moment a script has only been developed for 8 GB device `8gb_zynq7_sd.sfdisk`.

### Copy boot files

After completing the previous steps run `sync`. Disconnect and reconnect microSD card to PC. For Ubuntu 18+ OS it should automount the disk for you, and `boot` and `root` partitions should be accessible.

Boot files will be located in `plnx_root/images/linux` where `plnx_root` is the root folder of the PetaLinux project. These files are required

* `boot.scr`
* `BOOT.BIN`
* `image.ub`

```bash
cp -t /media/user/boot boot.scr BOOT.BIN image.ub
```

### Copy root file system

Ensure you're in the directory with the exploded file system. Replase `user` with the username on your system.

Minimal root file systems for Debian and Ubuntu can be obtained from <https://forum.digikey.com/t/debian-getting-started-with-the-zynq-7000/14380>

```bash
#Ubuntu; Root File System: user@localhost:~$
sudo tar xfvp ./ubuntu-*-*-armhf-*/armhf-rootfs-*.tar -C /media/user/root/
sync
sudo chown root:root /media/user/root/
sudo chmod 755 /media/user/root/
```

Setup fstab

```bash
#user@localhost:~/$
sudo sh -c "echo '/dev/mmcblk0p2  /  auto  errors=remount-ro  0  1' >> /media/user/root/etc/fstab"
sudo sh -c "echo '/dev/mmcblk0p1  /boot/uboot  auto  defaults  0  2' >> /media/user/root/etc/fstab"

sync
#Below optional: could use GUI to eject
sudo umount /media/user/boot
sudo umount /media/user/root
```

## First boot

> ⚠️ The system has a weak temporary initial password. Do *not* connect the Ethernet cable during the first boot.

Before powering on the board, connect J12 to a Micro USB cable and PC. This provides a serial connection for shell prompt, and also allows you to see the boot information printed (useful for debugging).

`picocom` is an easy to use Linux serial console command line utility. For an Ubuntu OS

```bash
sudo apt install picocom
```

The FTDI should present a new device, e.g. `ttyUSB0`. Connect to it at 115,200 baud

```bash
sudo picocom -b 115200 /dev/ttyUSB0
```

You will now have a normal bash terminal.

> ℹ️ The default login credentials are printed to the terminal. Use those to login and change the admin password to something stronger.

After the admin password has been changed, it's safe to connect the Ethernet cable. The OS is configured by default to use DHCP to obtain an IP. Networking should work out of the box without additional configuration on a DHCP capable LAN.

For board operation and bring up, privileged commands are used frequently, and constantly pasting password can be time consuming. This behavior can be disabled by modifying the sudo config using

```bash
sudo visudo
```

And adding the line

```bash
#Do not require password entry to run sudo commands
ubuntu ALL=(ALL) NOPASSWD: ALL
```

## Required packages

The board software (and better overall user experience) requires certain command line utilities, libraries and tools. For convenience they can be installed with these commands

```bash
sudo apt update
sudo apt install bash-completion git wget g++ python python3-numpy libi2c-dev make busybox libgsl-dev libzmq3-dev lsof vim htop screen python3-zmq
```

> ℹ️ nginx web server is installed by default, but can be removed if undesired.

## Changing host name

Use a unique Star Wars themed host name. Do not forget to make an inventory management entry which includes the IP address and physical location of the board.

```bash
sudo hostnamectl set-hostname drs4-name
```

Unfortunately this command does not seem to update `/etc/hosts` automatically (perhaps after a reboot). To avoid annoying messages about unresolved host names replace all instances of `arm` (or the original host name) in that file. For example, change the default config file below

```
127.0.0.1       localhost
127.0.1.1       arm.localdomain arm

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

to

```
127.0.0.1       localhost
127.0.1.1       drs4-name.localdomain drs4-name

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

### Convenience items

* Symlink busybox devmem
  * `cd /bin`
  * `sudo ln -s /bin/busybox devmem`

## Board software

The DAQ and slow control software can be obtained from <https://gitlab.com/ucla-gaps-tof/software>

## Board firmware

<https://gitlab.com/ucla-gaps-tof/firmware>

## TODO

* [ ] Create unified build approach: start with Enclustra BSP then auto patch UCLA customizations