set PATH_REPO [file normalize "[file normalize [file dirname [info script]]]/../../"]

update_ip_catalog

set_property top top_readout_board [current_fileset]

update_compile_order -fileset sources_1

set BD_FILE $PATH_REPO/bd/gaps_ps_interface/gaps_ps_interface.bd
add_files -norecurse $BD_FILE
open_bd_design [get_files $BD_FILE]
upgrade_bd_cells [get_bd_cells {*}]

# bd properties
set_property -dict [list CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {33.333333333333} CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1}] [get_bd_cells processing_system]
set_property -dict [list CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} CONFIG.PCW_MIO_40_SLEW {slow}] [get_bd_cells processing_system]

# Set an upper limit on SDIO frequency
set sdio_freq [get_property CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ  [get_bd_cells processing_system]]
if {50 < $sdio_freq} {
    Msg Error "SDIO frequency $sdio_freq set to higher than maximum allowed value!"
}

make_wrapper -files [get_files $BD_FILE] -top
add_files -norecurse $PATH_REPO/bd/gaps_ps_interface/hdl/gaps_ps_interface_wrapper.vhd

update_compile_order -fileset sources_1

# export from bd to tcl

# set origin_dir_loc $PATH_REPO
# open_bd_design [get_files -filter {NAME =~ *gaps_ps_interface.bd}]
# write_bd_tcl -no_ip_version -include_layout -force $PATH_REPO/bd/readout-board-bd.tcl
