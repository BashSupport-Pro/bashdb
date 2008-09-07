set trace-commands on
set basename on
# Test of miscellaneous commands: 
# 'source', 'info args', 'show args', 'show warranty', 'show copying', etc.
#### source command...
set width 75
source ../data/prof1.cmd
source ../data/prof2.cmd
#########################################
#### Test that ARGs are correct...
print "_Dbg_arg#: ${#_Dbg_arg[@]}"
print "\\$1: $1"
print "\\$2: $2"
#########################################
#### Testing script args...
## FIXME:
## info args
#########################################
tty
#### *** GNU things...
info warranty
#### help commands...
help
help set
help set foo
help set ar
help set annotate
help set listsize
help set prompt
help set editing
help tty
help info
info
#### history...
H
H 5
H 5 3
history 11
!11
!19:p
!-3:p
! -2
! 2
H -2
H foo
H 100000
history -2
history 10000
#### pwd/cd commands...
pwd
cd .
##########################
#### Test 'prompt' and 'tty' ...
set prompt bashdb${_Dbg_greater}$_Dbg_hi${_Dbg_less}$_Dbg_space
show prompt
tty /tmp/misc-output.check
l
#########################
#### Test 'file' command...
file data/misc.cmd
#### info variables (V) command...
V dq*
# On OS X there is some problem in doing the above and below commands
# in succession. Further investigation is needed to fix this. 
# Until then..
## info variables dq*
quit
