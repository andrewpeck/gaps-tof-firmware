set script_path "[file normalize [file dirname [info script]]]"
puts [exec bash $script_path/setup-gitfilters.sh]
