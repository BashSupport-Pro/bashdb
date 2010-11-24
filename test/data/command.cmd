set trace-commands on
# Debugger test of 'command' command
#
# Try to set command when there is none.
commands 1
#
# Now a command for a real breakpoint
break 23
commands 1
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
commands 2
print x is now $x
end
continue
####################################
# Now we'll change the it
####################################
commands 2
print "testing overwriting commands"
end
continue
####################################
# Should have seen the testing message
# above, not x. 
## FIXME: theres a weird bug 
## in evaluating expressions like $i
# Now let's remove the command 
# altogether
####################################
commands 2
end
continue
quit

