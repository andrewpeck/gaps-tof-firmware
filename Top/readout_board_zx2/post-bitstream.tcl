set PATH_REPO "[file normalize [file dirname [info script]]]/../../"

# If using 2021.1 c.f. https://www.xilinx.com/support/answers/75210.html
set dst_xsa [file normalize "$dst_dir/${proj_name}\-$describe.xsa"]
write_hw_platform -fixed -force -include_bit -file "$dst_xsa"

# Generate error on timing error
if [expr {[get_property SLACK [get_timing_paths -delay_type min_max]] < 0}] {
    error "ERROR: Timing failed"
}

# create a .bit.bin file using the fpga_manager python script
#
set cmd "cd [file normalize $PATH_REPO/util] && python3 create_fpga_manager_bin.py && cd -"

#https://www.xilinx.com/support/answers/72570.html
set PYTHONPATH $::env(PYTHONPATH)
set PYTHONHOME $::env(PYTHONHOME)
unset env(PYTHONPATH)
unset env(PYTHONHOME)
puts [exec bash -c $cmd]
set env(PYTHONPATH) $PYTHONPATH
set env(PYTHONHOME) $PYTHONHOME
