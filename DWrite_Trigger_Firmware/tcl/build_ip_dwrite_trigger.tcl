#DWRITE IP Core
set_part xc7z010clg400-1

#read_verilog  
add_files -norecurse ../hdl/dwrite_trigger.v
add_files -norecurse ../hdl/s_axi.v 
add_files -norecurse ../hdl/drs_trigger.v


synth_design -top dwrite_trigger

ipx::package_project -root_dir ../../ip_repo/DWRITE_TRIG -vendor UCLA -library GAPSFW -taxonomy GAPSFW  -import_files

 
set_property supported_families {zynq Production} [ipx::current_core]
set_property name DWrite_Trigger [ipx::current_core]
set_property display_name {DWriteTrig} [ipx::current_core]
set_property description {GAPS DWrite Controller} [ipx::current_core]
set_property vendor_display_name {University of California, Los Angeles} [ipx::current_core]


ipx::remove_bus_interface S_AXI_ARESETN [ipx::current_core]
ipx::infer_bus_interface S_AXI_ARESETN xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::associate_bus_interfaces -busif S_AXI_ACLK -clock S_AXI_ACLK [ipx::current_core]
ipx::associate_bus_interfaces -busif S_AXI_LITE -clock S_AXI_ACLK [ipx::current_core]

update_compile_order -fileset sources_1
 
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]

#opt_design
ipx::save_core [ipx::current_core]
update_ip_catalog

 

exit
 