# Test break, watch, watche, step, next, continue and stack handling
# $Id: brkpt2.cmd,v 1.1 2006/01/02 23:34:26 rockyb Exp $
#
p "*** Try a simple line number breakpoint..."
break 23
info break
cont
#
p "*** Try watch..."
watch x
info watchpoints
cont
p "*** Try disable expression..."
disable 1w
watche x > 26
info break
p "*** Continuing with a one-time line break (but will watch expression)..."
cont 30
L
p "*** Try deleting a watchpoint..."
delete 1W
L
p "*** Try break with a function..."
break fn1
p "*** Stepping 2..."
step 2
p "*** Try continue with a line number..."
cont 34
L
p "*** List stack frame..."
where
p "*** Try up..."
up
list
p "*** Try down 1..."
down 1
list
p "*** frame 0..."
frame 0
p "*** Try step (twice)..."
step
step
p "*** Try next and check that it jumps over fn3"
next
p "*** Try continue file:line (but will hit another breakpoint)..."
cont ./dbg-test1.sh:35
step 2
T
step 10
T
p "*** Try x command..."
x j
p "*** Try continue break no args (here)..."
break
cont
p "*** another x command..."
x j
p "*** another x command (+5 than value above) ..."
x j+5
p "*** x command of string y"
x y
p "*** x of a function ..."
x fn2
p "*** Bad x expressions ..."
x bogus
x bogus+
x fn2+fn3
x fn2+3
p "*** another continue. Count on breakpoint should go up."
cont
print "j: $j, name: $name"
p "*** Try disable of break "
disable 5
L
cont
p "*** Should hit end of script but stay in debugger..."
info files
p "*** quitting..."
quit
