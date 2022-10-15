#!/usr/bin/env bash
#
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

filter=$"
  sed 's/xc7z010/xc7z020/'
| sed 's/clg400/clg484/'
| sed 's/xspeedgrade\">.*</xspeedgrade\">-2</'
| sed 's/SPEEDGRADE\">.*</SPEEDGRADE\">-2</'"

git config -f $SCRIPTPATH/../../.git/config filter.reset_xci.clean "$(echo $filter)"
git config -f $SCRIPTPATH/../../.git/config filter.reset_xci.smudge "$(echo $filter)"

filter=$"sed -E s/\\(--\\)*\\(.*emio.*\\)/\\\\2/"

git config -f $SCRIPTPATH/../../.git/config filter.emio_filter.smudge "$(echo $filter)"
git config -f $SCRIPTPATH/../../.git/config filter.emio_filter.clean  "$(echo $filter)"
