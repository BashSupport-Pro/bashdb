set trace-commands on
set basename on
# Debugger test of action command
#
# Try a simple action action...
a
a 23 x=60
L
a
cont 24
print "value of x is now $x"
quit
set trace-commands on
