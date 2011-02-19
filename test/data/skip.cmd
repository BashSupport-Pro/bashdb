set trace-commands on
# Set initial value of x
next
# Test skip command
#
pr "x is $x"
# Try a skip command...
skip
pr "x is still $x"
# ** Try skipping over a for loop...
skip 
pr "x is still $x"
# Try skip with a count with backtick ...
skip 2
pr "x is still $x"
# ** Try skipping over a function call
skip
pr "x is still $x"
# Try skipping over another function call (with ;) at end
skip
next
pr "x is now $x"
# Try skip over a case
skip
# Try skip over first part of &&  expression
skip
pr "x is still $x"
# skip over arith expression
skip
pr "x is still $x"
skip
pr "*** quitting..."
quit
