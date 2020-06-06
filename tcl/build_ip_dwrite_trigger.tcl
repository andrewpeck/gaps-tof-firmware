puts "################################################################################"
puts "## Generating Trigger IP"
puts "################################################################################"

set_property top dwrite_trigger [current_fileset]
update_compile_order -fileset sources_1

set_property top dwrite_trigger [current_fileset]
update_compile_order -fileset sources_1
find_top
synth_design -top dwrite_trigger

ipx::package_project -root_dir [get_property DIRECTORY [current_project]]/../../ip/dwrite_trigger -vendor UCLA -library GAPSFW -taxonomy GAPSFW  -import_files

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

set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::unload_core [ipx::current_core]
