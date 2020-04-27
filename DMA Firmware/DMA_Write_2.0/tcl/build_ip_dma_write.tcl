#DMA Write Core
set_part xc7z010clg400-1

add_files -norecurse ../hdl/DMA_Write_v1_0.v
add_files -norecurse ../hdl/DMA_Write_v1_0_M00_AXI.v


add_files -norecurse ../hdl/DMA_WRITE_v1_0_STATUS.v
add_files -norecurse ../hdl/DMA_WRITE_v1_0_IRQ.v



read_ip ../ip/dma_ila/dma_ila.xci
read_ip ../ip/fifo_generator_1/fifo_generator_1.xci
read_ip ../ip/ila_0/ila_0.xci


 
	  
set locked [get_property IS_LOCKED [get_ips fifo_generator_1]]
set upgrade [get_property UPGRADE_VERSIONS [get_ips fifo_generator_1]]
 if {$locked && $upgrade != ""} {
     upgrade_ip [get_ips fifo_generator_1]}
	 
set locked [get_property IS_LOCKED [get_ips dma_ila]]
set upgrade [get_property UPGRADE_VERSIONS [get_ips dma_ila]]
 if {$locked && $upgrade != ""} {
     upgrade_ip [get_ips dma_ila]}
 
set locked [get_property IS_LOCKED [get_ips ila_0]]
set upgrade [get_property UPGRADE_VERSIONS [get_ips ila_0]]
 if {$locked && $upgrade != ""} {
     upgrade_ip [get_ips ila_0]}

generate_target all [get_ips dma_ila]
   
generate_target all [get_ips fifo_generator_1]

generate_target all [get_ips ila_0]

synth_design -top DMA_Write_v1_0

ipx::package_project -root_dir ../../ip_repo/DMA_Write -vendor UCLA -library GAPSFW -taxonomy GAPSFW  -import_files

 
 
#DMA Page
ipgui::add_page -name {DMA WRITE} -component [ipx::current_core] -display_name {Write DMA}
 

set_property supported_families {zynq Production} [ipx::current_core]
set_property name GAPS_WDMA [ipx::current_core]
set_property display_name {GAPS_WDMA} [ipx::current_core]
set_property description {Write DMA Core} [ipx::current_core]
set_property vendor_display_name {University of California, Los Angeles} [ipx::current_core]

set_property name DMA_AXI [ipx::get_bus_interfaces m00_axi -of_objects [ipx::current_core]]
set_property name DMA_SLAVE [ipx::get_bus_interfaces s_axi_lite -of_objects [ipx::current_core]]
ipx::associate_bus_interfaces -busif DMA_AXI -clock m00_axi_aclk [ipx::current_core]
ipx::associate_bus_interfaces -busif DMA_SLAVE -clock m00_axi_aclk [ipx::current_core]

ipx::remove_bus_interface m00_axi_aresetn [ipx::current_core]
ipx::infer_bus_interface m00_axi_aresetn xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

#FIFO Shenanigans
ipx::add_bus_interface FIFO [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:fifo_write_rtl:1.0 [ipx::get_bus_interfaces FIFO -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:fifo_write:1.0 [ipx::get_bus_interfaces FIFO -of_objects [ipx::current_core]]
ipx::add_port_map WR_DATA [ipx::get_bus_interfaces FIFO -of_objects [ipx::current_core]]
set_property physical_name din_dma [ipx::get_port_maps WR_DATA -of_objects [ipx::get_bus_interfaces FIFO -of_objects [ipx::current_core]]]
ipx::add_port_map WR_EN [ipx::get_bus_interfaces FIFO -of_objects [ipx::current_core]]
set_property physical_name wr_en [ipx::get_port_maps WR_EN -of_objects [ipx::get_bus_interfaces FIFO -of_objects [ipx::current_core]]]
ipx::add_port_map FULL [ipx::get_bus_interfaces FIFO -of_objects [ipx::current_core]]
set_property physical_name fifo_full [ipx::get_port_maps FULL -of_objects [ipx::get_bus_interfaces FIFO -of_objects [ipx::current_core]]]

ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces wr_aclk -of_objects [ipx::current_core]]

  
update_compile_order -fileset sources_1

ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]

#opt_design
ipx::save_core [ipx::current_core]
update_ip_catalog

exit
