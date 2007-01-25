set trace-commands on
set showcommand on
print "Test step inside multi-statement line..."
cont 15
step
step
step
p "BASH_SUBSHELL $BASH_SUBSHELL"
quit 0 2
print "You shouldn't get here. Quit again just in case..."
quit
