# $Id: restart.cmd,v 1.1 2006/01/02 23:34:26 rockyb Exp $
# Test Restart command
list
step
step
break 7
restart -B -q -L .. -x restart2.cmd restartbug.sh
# We never get here
quit 
