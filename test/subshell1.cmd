### Test step inside multi-statement line...
p "BASH_SUBSHELL: $BASH_SUBSHELL"
step 
step
step 
### Should now be inside a subshell...
p "BASH_SUBSHELL: $BASH_SUBSHELL"
print "Test unconditional quit..."
quit

