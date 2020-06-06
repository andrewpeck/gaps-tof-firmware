puts "################################################################################"
puts "## Generating DRS IP"
puts "################################################################################"

set_property top drs_top [current_fileset]
update_compile_order -fileset sources_1

upgrade_ip [get_ips clock_wizard]
upgrade_ip [get_ips sem_core]

generate_target all [get_ips clock_wizard]
generate_target all [get_ips sem_core]

set_property top drs_top [current_fileset]
update_compile_order -fileset sources_1
find_top
synth_design -top drs_top

ipx::package_project -root_dir [get_property DIRECTORY [current_project]]/../../ip/drs_top -vendor UCLA -library GAPSFW -taxonomy GAPSFW  -import_files

set_property supported_families {zynq Production} [ipx::current_core]
set_property name GAPS_DRS4 [ipx::current_core]
set_property display_name {GAPS_DRS4} [ipx::current_core]
set_property description {DRS4 Core} [ipx::current_core]
set_property vendor_display_name {University of California, Los Angeles} [ipx::current_core]

ipx::remove_bus_interface clock_i_n [ipx::current_core]
ipx::remove_bus_interface clock_i_p [ipx::current_core]
 
update_compile_order -fileset sources_1

ipx::update_source_project_archive -component [ipx::current_core]

ipx::save_core [ipx::current_core]
update_ip_catalog
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::unload_core [ipx::current_core]
