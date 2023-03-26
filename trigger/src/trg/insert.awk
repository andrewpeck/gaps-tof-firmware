BEGIN {
    start = ".*--START: autoinsert " heading
    end = ".*--END: autoinsert " heading
}

$0 ~ start {
    found_start = 1
}

$0 ~ end {
    found_end = 1
}

{
    if (!inserted && found_start) {
        print $0 "\n"
        system(cmd)
        inserted = 1
    }
    else if (!found_start || found_end) {
        print $0
    }
}
