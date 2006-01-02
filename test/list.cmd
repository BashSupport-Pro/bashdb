# 
# Test of debugger list command
# $Id: list.cmd,v 1.1 2006/01/02 23:34:26 rockyb Exp $
#
# List default location
pr "*** Trying 'list'..."
list 
# Should list next set of lines
print "*** Running another list..."
l
#
# Should not see anything since we ran off the top
# 
pr "*** Trying 'list 999'..."
list 999
pr "*** Trying 'list file:line' and canonicalization of filenames..."
list ./dbg-test1.sh:1
list ../test/dbg-test1.sh:20
list dbg-test1.sh:30
list ./dbg-test1.sh:999
list ./badfile:1
pr "*** Trying list of functions..."
list fn1
list bogus
#
pr "*** Testing window command..."
window 
# Test .
p "*** Testing '.'"
l . 
# 
# Should see lines up to current execution line.
p "*** Trying '-'..."
-
p "*** Testing set/show listsize"
show listsize
p "*** Setting listsize to 3..."
set listsize 3
l 10
p "*** Window command..."
w
p "- command..."
-
p "*** Setting listsize to 4..."
set listsize 4
show listsize
l 10
p "*** Window command..."
w
p "*** '-' command..."
-
#<-This comment doesn't have a space after 
#the initial `#'
quit
