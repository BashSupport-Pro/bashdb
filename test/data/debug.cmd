set trace-commands on
#### Test 'debug' command
continue 8
where 1
print running debug -n ./debug.sh $BASHDB_LEVEL ...
debug -B -q -x ../data/debug2.cmd ../example/debug.sh $BASHDB_LEVEL
quit




