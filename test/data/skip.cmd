set trace-commands on
# Test skip command
#
next
p "x is $x"
p "** Try a skip command..."
skip
p "x is still $x"
p "** Try skipping over a for loop..."
skip 
p "x is still $x"
p "** Try 'skip 3'..."
skip 3
p "x is still $x"
skip
p "x is still $x"
skip
next
p "x is still $x"
skip
skip
next
p "x is now $x"
skip
p "x is still $x"
skip
p "*** quitting..."
quit
