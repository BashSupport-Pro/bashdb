# Debugger test to see that parameter handling of $1, $2, etc is correct.
p $#
p $5
step
p $#
p $3
step
p $#
p $5
quit

