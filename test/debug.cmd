# $Id: debug.cmd,v 1.1 2006/01/02 23:34:26 rockyb Exp $
# Test debug command
continue 8
where
print running debug -n ./debug.sh $BASHDB_LEVEL ...
debug -q -x debug2.cmd ./debug.sh $BASHDB_LEVEL
quit




