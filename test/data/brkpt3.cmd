set trace-commands on
# Test break handling in the presence of subshells and canonicalization
# of breakpoints
#
break 15
step 4
###  Try a setting and removing break inside a subshell...
p "BASH_SUBSHELL: $BASH_SUBSHELL"
delete 1
break 17
cont

###  Try canonicalization of filenames in the break command...
b ../test/subshell.sh:1
b subshell.sh:2
b ./subshell.sh:3
###  quitting...
quit
