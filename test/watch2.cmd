# Test of dollar variables in watche, display and break condition
#
watche $? != 0
break fn3 if $1==30
display echo "1 is $1, ? is $?"
continue
continue
quit
