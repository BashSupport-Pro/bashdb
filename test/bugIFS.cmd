# $Id: bugIFS.cmd,v 1.1 2006/01/02 23:34:26 rockyb Exp $
# Debugger test of an old IFS bug
#
print "Going to the location where IFS should be reset in the code..."
continue 5
e _Dbg_print_source_line 5
quit

