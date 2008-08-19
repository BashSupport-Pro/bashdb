set trace-commands on
# Test break, watch, watche, step, next, continue and stack handling
#
###  Try a simple line number breakpoint...
break 23
info break
continue
info program
#
###  Try watch...
watch x
info watchpoints
c
info program
###  Try disable expression...
disable 1w
watche x > 26
info break
###  Continuing with a one-time line break (but will watch expression)...
cont 30
L
###  Try deleting a watchpoint...
delete 1W
L
###  Try break with a function...
break fn1
###  Stepping 2...
step 2
###  Try continue with a line number...
cont 34
info program
L
###  List stack frame...
where
###  Try up...
up
list
###  Try down 1...
down 1
list
###  frame 0...
frame 0
###  Try step (twice)...
step
info program
step
###  Try next and check that it jumps over fn3
next
###  Try continue file:line (but will hit another breakpoint)...
cont ./example/dbg-test1.sh:35
step 2
T
step 10
T
###  Try x command...
x j
###  Try continue break no args (here)...
break
cont
###  another x command...
x j
###  another x command (+5 than value above) ...
x j+5
###  x command of string y
x y
###  x of a function ...
x fn2
###  Bad x expressions ...
x bogus
x bogus+
x fn2+fn3
x fn2+3
###  another continue. Count on breakpoint should go up.
cont
print "j: $j, name: $name"
###  Try disable of break 
disable 5
L
cont
### Test temporary break and its reporting
cont 13
info program
###  Should hit end of script but stay in debugger...
cont
info files
###  quitting...
quit
