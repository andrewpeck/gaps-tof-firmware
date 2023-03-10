# all:
# make process
# make insert

insert:
	@awk -v cmd='make --silent mapping' -f insert.awk trigger.vhd > tmp.vhd
	@mv tmp.vhd trigger.vhd

get:
	wget --output-document="mapping.csv" \
		https://docs.google.com/spreadsheets/d/1i41fsmLf7IjfYbr1coTo9V4uk3t1GXAGgt0aOeCkeeA/gviz/tq?tqx=out:csv

mapping:
	@awk -f process_mapping.awk mapping.csv
