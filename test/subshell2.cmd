set showcommand on
print "Test quit inside multi-statement line..."
step 
step
step 2
print "Should now be inside a subshell. Test from here..."
p "BASH_SUBSHELL: $BASH_SUBSHELL"
print "Test quit 0 2..."
quit 0 2
print "You shouldn't get here. Another just in case."
quit

