set trace-commands on
set basename on
# Debugger test of action command, and some $ vars
#
# Show actions
a
# Delete actions when there are none
A
# Try a simple action action...
a 23 x=60
L
a
cont 24
print "value of x is now $x"
# Check $0
eval echo dollar 0 is $(basename $0)
quit
