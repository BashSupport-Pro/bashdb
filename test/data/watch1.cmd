set trace-commands on
# Test of watchpoint handling
#
###  Should fail since xyxxy is not defined...
watch xyxxy
info watch
###  Test a simple breakpoint...
eval xx=1
watch xx
info watch
#
# Now try enable and disable
#
###  Try testing enable/disable...
enable  0w
L
disable 0W
L
###  Try deleting nonexistent watchpoint...
delete 10w
# 
###  Test display of watchpoints...
watche y > 25
info watch
delete 0w
info watch
delete 1w
info watch
step
watch x
restart -B --nx -L ../.. -q -x ../data/restart2.cmd ../example/dbg-test1.sh
quit
