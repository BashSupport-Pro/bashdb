# 
# Test of watchpoint handling
# $Id: watch1.cmd,v 1.1 2006/01/02 23:34:27 rockyb Exp $
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
quit
