# PetaLinux source files and documentation

[[_TOC_]]

## Organization

``` {.example}
plnx/
  ├── dtsi                : Deprecated, old dts config
  ├── enclustra           : Original source files for Enclustra BSP
  ├── project_spec_config : Deprecated, old plnx config
  └── ucla/project-spec   : Source for UCLA DRS4 PetaLinux build
```

## Requirements
 * Vivado 2020.1
 * PetaLinux 2020.1
 * [firmware](https://gitlab.com/ucla-gaps-tof/firmware)
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
```
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
```
petalinux-create -t project -s /path/to/enclustra.bsp
petalinux-configure --get-hw-description=/path/to/.xsa
```
 * Modify device tree files to match those of `ucla/project-spec/meta-user/recipes-bsp/device-tree/files` 
 * Build
```
petalinux-build
petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot --force
```
 * Copy following files to `boot` partition of the SD card
   * `BOOT.BIN`
   * `boot.scr`
   * `image.ub`
