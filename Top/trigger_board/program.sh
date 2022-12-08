#!/usr/bin/env bash
VIVADO=$(command -v vivado || command -v vivado_lab)

if [[ ! -z "$VIVADO" ]]; then
   vivado -mode batch -source program.tcl -notrace
else
    echo "ERROR: Vivado not found in path."
fi
