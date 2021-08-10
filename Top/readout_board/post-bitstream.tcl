# If using 2021.1 c.f. https://www.xilinx.com/support/answers/75210.html
set dst_xsa [file normalize "$dst_dir/${proj_name}\-$describe.xsa"]
write_hw_platform -fixed -force -include_bit -file "$dst_xsa"

# Generate error on timing error
if [expr {[get_property SLACK [get_timing_paths -delay_type min_max]] < 0}] {
    error "ERROR: Timing failed"
}
