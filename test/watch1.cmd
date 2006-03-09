# 
# Test of watchpoint handling
# $Id: watch1.cmd,v 1.2 2006/03/09 11:28:57 rockyb Exp $
#
print "*** Should fail since xyxxy is not defined..."
watch xyxxy
info break
print "*** Test a simple breakpoint..."
eval xx=1
watch xx
info break
#
# Now try enable and disable
#
print "*** Try testing enable/disable..."
en  0w
L
dis 0W
L
print "*** Try deleting nonexistent watchpoint..."
delete 10w
# 
print "*** Test display of watchpoints..."
watche y > 25
info break
delete 0w
info break
delete 1w
info break
step
watch x
restart -B -q -L .. -x restart2.cmd dbg-test1.sh
quit
