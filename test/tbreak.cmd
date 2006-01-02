# $Id: tbreak.cmd,v 1.1 2006/01/02 23:34:26 rockyb Exp $
# Test temporary break
#
p "*** Try a simple temporary breakpoint..."
tbreak 23
info break
p "*** Should continue to line 23..."
cont
p "*** Go on to line 25..."
step 4
p "*** Try a temporary breakpoint here (line 25)..."
tbreak
p "*** And another a temporary breakpoint at fn3..."
tbreak fn3
L
step 2
L
p "*** Should not not see line 25 above and not stop again. Continue to fn3..."
cont
L
p Should end but stay in debugger..
cont
p "***quitting..."
quit

