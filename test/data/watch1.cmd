set trace-commands on
# Test of watchpoint handling
#
###  Should fail since xyxxy is not defined...
watch xyxxy
info break
###  Test a simple breakpoint...
eval xx=1
watch xx
info break
#
# Now try enable and disable
#
###  Try testing enable/disable...
en  0w
L
dis 0W
L
###  Try deleting nonexistent watchpoint...
delete 10w
# 
###  Test display of watchpoints...
watche y > 25
info break
delete 0w
info break
delete 1w
info break
step
watch x
restart -B -L .. -q -x data/restart2.cmd example/dbg-test1.sh
quit
