set trace-commands on
set showcommand on
print "Test step inside multi-statement line..."
cont 15
step
step
step
pr "BASH_SUBSHELL $BASH_SUBSHELL"
quit 0 56
quit
