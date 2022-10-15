set script_path "[file normalize [file dirname [info script]]]"
puts [exec sh $script_path/setup-gitfilters.sh]
