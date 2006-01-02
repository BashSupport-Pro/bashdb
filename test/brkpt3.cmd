# Test break handling in the presence of subshells and canonicalization
# of breakpoints
# $Id: brkpt3.cmd,v 1.1 2006/01/02 23:34:26 rockyb Exp $
#
break 15
step 4
p "*** Try a setting and removing break inside a subshell..."
p "BASH_SUBSHELL: $BASH_SUBSHELL"
delete 1
break 17
cont

p "*** Try canonicalization of filenames in the break command..."
b ../test/subshell.sh:1
b subshell.sh:2
b ./subshell.sh:3
p "*** quitting..."
quit
