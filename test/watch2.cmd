# 
# Test of dollar variables in watche, display and break condition
# $Id: watch2.cmd,v 1.1 2006/01/02 23:34:27 rockyb Exp $
#
watche $? != 0
break fn3 if $1==30
display echo "1 is $1, ? is $?"
continue
continue
quit
