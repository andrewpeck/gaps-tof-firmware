set basename [file rootname [lindex [glob *.bit] 0]]
set bitfile ${basename}.bit
set binfile ${basename}.bin
set ltxfile ${basename}.ltx

proc program_flash {binfile devicename flash} {

    puts " > Programming Flash"

    set device [lindex [get_hw_devices $devicename] 0]
    set program_hw_cfgmem [get_property PROGRAM.HW_CFGMEM $device]

    create_hw_cfgmem -hw_device $device [lindex [get_cfgmem_parts $flash] 0]
    set_property PROGRAM.BLANK_CHECK 0 [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.ERASE 1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7k160t_0] 0]]
    set_property PROGRAM.CFG_PROGRAM  1 [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.VERIFY  1 [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.CHECKSUM  0 [get_property PROGRAM.HW_CFGMEM $device]

    refresh_hw_device -quiet $device

    set_property PROGRAM.ADDRESS_RANGE  {use_file} [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.FILES [list "$binfile" ] [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.PRM_FILE {} [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.BLANK_CHECK  0 [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.ERASE  1 [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.CFG_PROGRAM  1 [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.VERIFY  1 [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.CHECKSUM  0 [get_property PROGRAM.HW_CFGMEM $device]

    create_hw_bitstream -hw_device $device [get_property PROGRAM.HW_CFGMEM_BITFILE $device];
    program_hw_devices $device;
    refresh_hw_device -quiet $device;
    program_hw_cfgmem -hw_cfgmem [get_property PROGRAM.HW_CFGMEM $device]
}

proc select_hw_targets {} {

    # find a port with hardware targets on it
    foreach port [list 2542 3121] {
        connect_hw_server -url localhost:$port -allow_non_jtag
        set targets [get_hw_targets]
        set num_targets [llength $targets]
        if {$num_targets > 0} {
            break
        }
    }

    # make a dictionary of the device names (e.g. xc7v...)
    set devices ""
    if {$num_targets > 0} {
        foreach target $targets {
            close_hw_target
            open_hw_target $target
            set device [get_hw_devices]
            dict set devices $target $device
            close_hw_target
        }
    }

    if {$num_targets == 0} {
        error "No hardware targets found"
    } elseif {[llength $targets] == 1} {
        set target [lindex 0 $targets]
        puts "Target $target [dict get $devices $target] found, press any key to continue."
        puts "   > Device: "
        gets stdin select
    } elseif {[llength $targets] > 1} {
        puts "Multiple hardware targets found"
        for {set i 0} {$i < $num_targets} {incr i} {
            set target [lindex $targets $i]
            puts "  > $i $target"
            puts "      [dict get $devices $target]"
        }
        puts "  > \"all\" to program all"

        puts "Please select a target:"

        gets stdin select

        puts "$select selected"

        if {[string equal $select "all"]} {
            set targets $targets
        } elseif {$select > $num_targets-1} {
            error "Invalid target selected"
        } else {
            set targets [lindex $targets $select]
            puts " > selected $targets"
        }
    }
    return $targets
}

open_hw_manager

set targets [select_hw_targets]

foreach target $targets {
    puts " > Programming $target"
    get_hw_targets
    open_hw_target $target
    set device [get_hw_devices]
    if {[llength $device] > 0} {

        if {[string equal $device "xc7k160t_0"]} {
            puts "Master trigger board selected... do you want to program the Flash? y/n"
            gets stdin select
            if {[string equal $select "y"]} {
                program_flash $binfile "xc7k160t_0" "mt25ql01g-spi-x1_x2_x4"
            }
        }

        puts " > Programming FPGA"
        current_hw_device [get_hw_devices $device]
        refresh_hw_device -quiet -update_hw_probes false $device
        set_property PROGRAM.FILE $bitfile $device
        set_property PROBES.FILE $ltxfile $device
        set_property FULL_PROBES.FILE $ltxfile $device
        program_hw_devices $device

    }
    close_hw_target
}

