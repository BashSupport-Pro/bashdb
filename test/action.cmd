# Debugger test of action command
#
# Try a simple action breakpoint...
a 23 x=60
L
cont 24
print "value of x is now $x"
quit

