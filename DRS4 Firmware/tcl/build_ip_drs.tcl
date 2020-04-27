 #DRS4 Core
 set_part xc7z010clg400-1

 #pkg files
 add_files -norecurse ../hdl/pkg/axi_pkg.vhd
 add_files -norecurse ../hdl/pkg/ipbus_pkg.vhd
 add_files -norecurse ../hdl/pkg/registers.vhd
 add_files -norecurse ../hdl/pkg/types_pkg.vhd
 
 add_files -norecurse ../hdl/daq_board_top.vhd
 add_files -norecurse ../hdl/drs.v
 add_files -norecurse ../hdl/dna.v
 add_files -norecurse ../hdl/crc22.v
 add_files -norecurse ../hdl/axi_ipbus_bridge.vhd
 add_files -norecurse ../hdl/counter.vhd
 add_files -norecurse ../hdl/counter_snap.vhd
 add_files -norecurse ../hdl/ipbus_slave.vhd
 add_files -norecurse ../hdl/majority.vhd
 add_files -norecurse ../hdl/sem.vhd
 add_files -norecurse ../hdl/synchonizer.vhd

 

 read_ip ../ip/clock_wizard/clock_wizard.xci
 read_ip ../ip/sem_core/sem_core.xci
   
 set locked [get_property IS_LOCKED [get_ips clock_wizard]]
 set upgrade [get_property UPGRADE_VERSIONS [get_ips clock_wizard]]
 if {$locked && $upgrade != ""} {
     upgrade_ip [get_ips clock_wizard]}
 
 set locked [get_property IS_LOCKED [get_ips sem_core]]
 set upgrade [get_property UPGRADE_VERSIONS [get_ips sem_core]]
 if {$locked && $upgrade != ""} {
     upgrade_ip [get_ips sem_core]}
	 
 generate_target all [get_ips clock_wizard]
    
 generate_target all [get_ips sem_core]
 
 synth_design -top drs_top

 ipx::package_project -root_dir ../../ip_repo/DRS -vendor UCLA -library GAPSFW -taxonomy GAPSFW  -import_files
 

set_property supported_families {zynq Production} [ipx::current_core]
set_property name GAPS_DRS4 [ipx::current_core]
set_property display_name {GAPS_DRS4} [ipx::current_core]
set_property description {DRS4 Core} [ipx::current_core]
set_property vendor_display_name {University of California, Los Angeles} [ipx::current_core]

ipx::remove_bus_interface clock_i_n [ipx::current_core]
ipx::remove_bus_interface clock_i_p [ipx::current_core]

  
update_compile_order -fileset sources_1

ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]

#opt_design
ipx::save_core [ipx::current_core]
update_ip_catalog

exit
