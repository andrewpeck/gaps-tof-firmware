# If using 2021.1 c.f. https://www.xilinx.com/support/answers/75210.html
set dst_xsa [file normalize "$dst_dir/${proj_name}\-$describe.xsa"]
write_hw_platform -fixed -force -include_bit -file "$dst_xsa"
