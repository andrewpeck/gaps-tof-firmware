set filter {sed 's/xc7z010/xc7z020/' | \
                sed 's/clg400/clg484/' | \
                sed 's/xspeedgrade">.*</xspeedgrade">-2</' | \
                sed 's/SPEEDGRADE">.*</SPEEDGRADE">-2</'}
exec git config --local filter.reset_xci.clean $filter
exec git config --local filter.reset_xci.smudge $filter

set filter {sed -E s/\(--\)*\(.*emio.*\)/\\2/}
exec git config --local filter.emio_filter.smudge $filter
exec git config --local filter.emio_filter.clean $filter
