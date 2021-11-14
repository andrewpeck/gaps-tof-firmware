#!/bin/bash

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
     (require 'org)
     (require 'org-table)
     (mapc (lambda (file)
            (find-file (expand-file-name file \"$DIR\"))
            (print (format \"Fixing tables in %s\" buffer-file-name))
            (org-table-map-tables 'org-table-align)
            (save-buffer)
            (kill-buffer)) '($FILES)))"
