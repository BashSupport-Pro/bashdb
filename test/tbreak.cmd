# Test temporary break
#
### a simple temporary breakpoint...
tbreak 23
info break
### continue to line 23...
cont
### on to line 25...
step 4
### a temporary breakpoint here (line 25)...
tbreak
### another a temporary breakpoint at fn3...
tbreak fn3
L
step 2
L
### not not see line 25 above and not stop again. Continue to fn3...
cont
L
### Should end but stay in debugger..
cont
### Try some commands that require a running debugger
up 1
down
frame 0
where
info line
step
next
continue
### quitting...
quit

