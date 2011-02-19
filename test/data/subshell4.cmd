set trace-commands on
set showcommand 1
print "Test step inside multi-statement lines and subshells..."
step 1
step 3
pr "BASH_SUBSHELL $BASH_SUBSHELL"
step
H
pr "BASH_SUBSHELL $BASH_SUBSHELL"
step
H
pr "BASH_SUBSHELL $BASH_SUBSHELL"
step
H
pr "BASH_SUBSHELL $BASH_SUBSHELL"
step
H
pr "BASH_SUBSHELL $BASH_SUBSHELL"
step
H
pr "BASH_SUBSHELL $BASH_SUBSHELL"
step
H
pr "BASH_SUBSHELL $BASH_SUBSHELL"
step
H
pr "BASH_SUBSHELL $BASH_SUBSHELL"
step
pr "BASH_SUBSHELL $BASH_SUBSHELL"
step
pr "BASH_SUBSHELL $BASH_SUBSHELL"
step
pr "BASH_SUBSHELL $BASH_SUBSHELL"
step
H
pr "BASH_SUBSHELL $BASH_SUBSHELL"
quit
