# $Id: action.cmd,v 1.1 2006/01/02 23:34:26 rockyb Exp $
# Debugger test of action command
#
p "** Try a simple action breakpoint..."
a 23 x=60
L
cont 24
print "value of x is now $x"
quit

