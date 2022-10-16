#!/usr/bin/env bash
#
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

filter=$"
  sed 's/kintex7/zynq/'
| sed 's/fbg676/clg484/'
| sed 's/xc7k160t/xc7z020/'
| sed 's/c_device_array\">33554434</c_device_array\">67108866</'
| sed 's/xspeedgrade\">.*</xspeedgrade\">-2</'
| sed 's/SPEEDGRADE\">.*</SPEEDGRADE\">-2</'"

git config -f $SCRIPTPATH/../../.git/config filter.reset_xci.clean "$(echo $filter)"
git config -f $SCRIPTPATH/../../.git/config filter.reset_xci.smudge "$(echo $filter)"
