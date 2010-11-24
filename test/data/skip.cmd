set trace-commands on
# Set initial value of x
next
# Test skip command
#
p "x is $x"
# Try a skip command...
skip
p "x is still $x"
# ** Try skipping over a for loop...
skip 
p "x is still $x"
# Try skip with a count with backtick ...
skip 2
p "x is still $x"
# ** Try skipping over a function call
skip
p "x is still $x"
# Try skipping over another function call (with ;) at end
skip
next
p "x is now $x"
# Try skip over a case
skip
# Try skip over first part of &&  expression
skip
p "x is still $x"
# skip over arith expression
skip
p "x is still $x"
skip
p "*** quitting..."
quit
