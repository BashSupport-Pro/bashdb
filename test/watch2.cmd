# Test of dollar variables in watche, display and break condition
#
watche $? != 0
step
break fn3 if x==29
display echo "x is $x, ? is $?"
continue
continue
quit
