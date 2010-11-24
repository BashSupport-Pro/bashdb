set trace-commands on
# Test Restart command
list
step
step
break 7
restart -B --no-init -q -L ../.. -x ../../test/data/restart2.cmd ../../test/example/restartbug.sh
# We never get here
print You should not see this.
quit 
