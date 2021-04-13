
# (must be a tcl file, placements aren't supported in xdc ugh)


# hand place the dwrite output luts somewhere close to the dwrite_obuf
# seems to help keep the routing time down and more consistent
# keep them in the same slice
place_cell  [get_cells trigger_mux_inst/drs_dwrite_o*]  SLICE_X43Y45/D6LUT

place_cell  [get_cells -of_objects [get_nets trigger_mux_inst/ext_trigger_i]] \
             SLICE_X43Y45/C6LUT

place_cell  [get_cells trigger_mux_inst/trigger_r_*]      SLICE_X43Y45/C5FF