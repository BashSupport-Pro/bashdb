set trace-commands on
#### Test 'debug' command
continue 8
where
print running debug -n ./debug.sh $BASHDB_LEVEL ...
debug -q -x ../data/debug2.cmd ../example/debug.sh $BASHDB_LEVEL
quit




