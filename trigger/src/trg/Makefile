update:
	make --silent update_mapping
	make --silent mapping
	make --silent rbmap
	emacs -batch -Q trigger.vhd -f vhdl-beautify-buffer

# triggers:
# 	@awk -v heading="triggers" -v cmd='bb generate_triggers.bb' -f insert.awk trigger.vhd > tmp.vhd
# 	@mv tmp.vhd trigger.vhd

mapping:
	@awk -v heading="mapping" -v cmd='make --silent process_mapping' -f insert.awk trigger.vhd > tmp.vhd
	@mv tmp.vhd trigger.vhd

rbmap:
	@awk -v heading="mapping" -v cmd='make --silent process_rbmap | sort -n -t "(" -k2' -f insert.awk rb_map.vhd > tmp.vhd
	@mv tmp.vhd rb_map.vhd

update_mapping:
	wget --output-document='mapping-validated.json' https://raw.githubusercontent.com/GAPS-Collab/gaps-tof-channel-mapping/master/mapping-validated.json

process_mapping:
	bb process_mapping.bb --map-ltb

process_rbmap:
	bb process_mapping.bb --map-rb
