set trace-commands on
set showcommand 1
#### Test step inside multi-statement line...
step 
step
step 2
#### Should now be inside a subshell. Test from here...
pr "BASH_SUBSHELL: $BASH_SUBSHELL"
quit 0 2
quit

