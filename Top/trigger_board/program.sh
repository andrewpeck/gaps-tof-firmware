#!/usr/bin/env bash
VIVADO=$(command -v vivado || command -v vivado_lab)

if [[ ! -z "$VIVADO" ]]; then
   $VIVADO -mode batch -source program.tcl -notrace
else
    echo "ERROR: Vivado not found in path."
fi
