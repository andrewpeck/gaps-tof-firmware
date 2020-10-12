#vivado
############# modify these to match project ################
set BIN_FILE 0
set SIMULATOR  xsim

## FPGA and Vivado strategies and flows
set FPGA xc7z010clg400-1

regexp -- {Vivado v([0-9]{4})\.[0-9]} [version] -> VIVADO_YEAR
set SYNTH_STRATEGY "Vivado Synthesis Defaults"
set SYNTH_FLOW "Vivado Synthesis $VIVADO_YEAR"
set IMPL_STRATEGY "Vivado Implementation Defaults"
set IMPL_FLOW "Vivado Implementation $VIVADO_YEAR"

### Set Vivado Runs Properties ###
#
# ATTENTION: The \ character must be the last one of each line
#
# The default Vivado run names are: synth_1 for synthesis and impl_1 for implementation.
#
# To find out the exact name and value of the property, use Vivado GUI to click on the checkbox you like.
# This will make Vivado run the set_property command in the Tcl console.
# Then copy and paste the name and the values from the Vivado Tcl console into the lines below.

set PROPERTIES [dict create \
                    synth_1 [dict create \
                                 STEPS.SYNTH_DESIGN.ARGS.ASSERT true \
                                 STEPS.SYNTH_DESIGN.ARGS.RETIMING false \
                                 STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT 500 \
                                ] \
                    impl_1 [dict create \
                                STEPS.PHYS_OPT_DESIGN.IS_ENABLED true \
                                STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true \
                                STEPS.OPT_DESIGN.ARGS.DIRECTIVE Default \
                                STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE Default \
                               ]\
                   ]

############################################################


############################################################
set DESIGN    "[file rootname [file tail [info script]]]"
set PATH_REPO "[file normalize [file dirname [info script]]]/../../"

source $PATH_REPO/Hog/Tcl/create_project.tcl

#set_property  ip_repo_paths  $PATH_REPO/ip [current_project]
update_ip_catalog

set_property top drs_top [current_fileset]

update_compile_order -fileset sources_1

open_bd_design [get_files $PATH_REPO/bd/gaps_ps_interface/gaps_ps_interface.bd]
upgrade_bd_cells [get_bd_cells {*}]
make_wrapper -files [get_files $PATH_REPO/bd/gaps_ps_interface/gaps_ps_interface.bd] -top
add_files -norecurse $PATH_REPO/bd/gaps_ps_interface/hdl/gaps_ps_interface_wrapper.vhd

update_compile_order -fileset sources_1
