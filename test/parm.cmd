# Debugger test of: 
#  stack trace 
#  parameter display 
#  return command
#  evaluation of dollar variables $1, $2
#
###  Try a simple stack command...
where
step 2
where
###  Try printing a dollar variable...
p $1
###  Same thing using eval...
eval echo $1
###  Setting an action to print $1
a 4 echo "\\$1 at line 4 has value $1"
c fn2
# cont
###  First parameter should have embedded blanks...
where
p "dollar 1: $1"
###  Same thing using eval...
e echo "\\$1 is $1"
###  Should have embedded blanks...
p $2
e echo "\\$2 is $2"
continue fn3
###  Test return. Should go back to fn2 and then fn1...
return
return
###  Should not have done above-listed x=\"fn2\" assignment
p $x
where
return
where
return
where
return
return
where
### * Testing that exit status preserved on eval and print...
c 29
e echo "eval says exit was $?"
p "print says exit was $?"
info files
### * quitting...
quit
