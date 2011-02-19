set trace-commands on
# Debugger test of: 
#  stack trace 
#  parameter display 
#  return command
#  evaluation of dollar variables $1, $2
#
###  Try a simple stack command...
where 1
step 2
where 2
###  Try printing a dollar variable...
pr $1
###  Same thing using eval...
eval echo $1
###  Setting an action to print $1
a 4 echo "\\$1 at line 4 has value $1"
c fn2
# cont
###  First parameter should have embedded blanks...
where 8
pr "dollar 1: $1"
###  Same thing using eval...
ev echo "\\$1 is $1"
###  Should have embedded blanks...
pr $2
ev echo "\\$2 is $2"
continue fn3
###  Test return. Should go back to fn2 and then fn1...
return
return
###  Should not have done above-listed x=\"fn2\" assignment
pr $x
where 7
return
where 6
return
where 5
return
return
where 3
### * Testing that exit status preserved on eval and print...
c 29
ev echo "eval says exit was $?"
pr "print says exit was $?"
info files
### * quitting...
quit
