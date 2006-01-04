# $Id: restart.cmd,v 1.2 2006/01/04 07:45:12 rockyb Exp $
# Test Restart command
list
step
step
break 7
restart -B -q -L .. -x restart2.cmd restartbug.sh
# We never get here
print You should not see this.
quit 
