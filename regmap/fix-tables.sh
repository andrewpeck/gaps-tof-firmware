#!/bin/sh
# -*- mode: shell-script -*-
#
# tangle files with org-mode
#
DIR=$(pwd)
FILES=""
# wrap each argument in the code required to call tangle on it
for i in "$@"; do
FILES="$FILES \"$i\""
done

if ! command -v emacs &> /dev/null
then
    echo "Emacs not in path :("
    exit
fi

emacs -Q --batch \
--eval "(progn
     (require 'org)(require 'org-table)
     (mapc (lambda (file)
            (find-file (expand-file-name file \"$DIR\"))
            (org-table-map-tables 'org-table-align)
            (write-file file nil)
            (kill-buffer)) '($FILES)))"
