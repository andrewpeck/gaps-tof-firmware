# promote multi-driven nets to errors
set_msg_config -quiet -id {Synth 8-6859} -new_severity {ERROR}
# demote verilog parameter becoming local
set_msg_config -quiet -id {Synth 8-2507} -new_severity {INFO}


# replace the confusing Hog VER/SHA with one that actually makes sense

lassign [GetVer [Git ls-files]] repo_ver repo_sha

set generic_string [get_property generic [current_fileset]]

if {[string first REPO_SHA $generic_string] != -1} {
    regsub -all "REPO_SHA=32'h[0-9,A-f]*" $generic_string "REPO_SHA=$repo_sha" generic_string
} else {
    set generic_string "$generic_string REPO_SHA=$repo_sha"
}

if {[string first REPO_VER $generic_string] != -1} {
    regsub -all "REPO_VER=32'h[0-9,A-f]*" $generic_string "REPO_VER=$repo_ver" generic_string
} else {
    set generic_string "$generic_string REPO_VER=$repo_ver"
}

puts "================================================================================"
puts $generic_string
puts "================================================================================"

set_property generic $generic_string [current_fileset]
