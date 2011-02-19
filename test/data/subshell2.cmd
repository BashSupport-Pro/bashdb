set trace-commands on
set showcommand on
### Test quit inside multi-statement line...
step 
step
step 2
### Should now be inside a subshell. Test from here...
pr "BASH_SUBSHELL: $BASH_SUBSHELL"
### Test quit 0 2...
quit 0 2
### You shouldn't get here. Another just in case.
quit

