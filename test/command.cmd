# Debugger test of 'command' command
#
# Try to set command when there is none.
command 1
#
# Now a command for a real breakpoint
break 23
command 1
x x
end
#
##############################
# Should see value of x below
# from the command statment
break 25
continue
#
#############################
# Test of a changing
# command statement. First
# The setup.
##############################
command 2
print x is now $x
end
continue
####################################
# Now we'll change the it
####################################
command 2
print "testing overwriting commands"
print i is $i
end
continue
####################################
# Should have seen value of i
# above, not x. Now let's remove
# the command altogher
####################################
command 2
end
continue
quit

