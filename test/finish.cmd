# $Id: finish.cmd,v 1.1 2006/01/02 23:34:26 rockyb Exp $
# Debugger test of: 
#  finish command
#
p "*** Try a simple finish..."
continue fn2
where
finish
where
print $x
quit
