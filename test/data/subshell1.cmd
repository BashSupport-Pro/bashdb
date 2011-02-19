set trace-commands on
### Test step inside multi-statement line...
pr "BASH_SUBSHELL: $BASH_SUBSHELL"
step 
step
step 
### Should now be inside a subshell...
pr "BASH_SUBSHELL: $BASH_SUBSHELL"
print "Test unconditional quit..."
quit

