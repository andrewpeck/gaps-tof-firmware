update:
	make --silent mapping
	make --silent rbmap
	make --silent triggers
	emacs -batch -Q trigger.vhd -f vhdl-beautify-buffer

triggers:
	@awk -v heading="triggers" -v cmd='bb generate_triggers.bb' -f insert.awk trigger.vhd > tmp.vhd
	@mv tmp.vhd trigger.vhd

mapping:
	@awk -v heading="mapping" -v cmd='make --silent process_mapping' -f insert.awk trigger.vhd > tmp.vhd
	@mv tmp.vhd trigger.vhd

rbmap:
	@awk -v heading="mapping" -v cmd='make --silent process_rbmap' -f insert.awk rb_map.vhd > tmp.vhd
	@mv tmp.vhd rb_map.vhd

update_mapping:
	wget --output-document="mapping.csv" \
		https://docs.google.com/spreadsheets/d/1i41fsmLf7IjfYbr1coTo9V4uk3t1GXAGgt0aOeCkeeA/gviz/tq?tqx=out:csv

process_mapping:
	@awk -v print_hitmask=1 -f process_mapping.awk mapping.csv

process_rbmap:
	@awk -v print_rbmap=1 -f process_mapping.awk mapping.csv
