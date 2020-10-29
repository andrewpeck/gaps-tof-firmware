set dst_xsa [file normalize "$dst_dir/$name\-$describe.xsa"]
write_hw_platform -fixed -force -include_bit -file "$dst_xsa"
