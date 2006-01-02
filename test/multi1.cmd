print "Test step inside multi-statement line..."
p "BASH_SUBSHELL: $BASH_SUBSHELL"
step 
step
step 
print "Should now be inside a subshell..."
p "BASH_SUBSHELL: $BASH_SUBSHELL"
quit

