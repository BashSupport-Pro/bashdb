set trace-commands on
# Test of miscellaneous commands: 
# 'source', 'info args', 'show args', 'show warranty', 'show copying', etc.
#### source command...
source prof1.cmd
source prof2.cmd
#########################################
#### Test that ARGs are correct...
print "_Dbg_arg#: ${#_Dbg_arg[@]}"
print "\\$1: $1"
print "\\$2: $2"
#########################################
#### Testing script args...
info args
#########################################
#### Invalid commands...
show badcommand
another-bad-command
tty
#### *** GNU things...
show warranty
info warranty
show copying
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
show
#### and show...
show args
set args now is the time
show args
set editing off
set editing fooo
show editing
set editing
show editing
set misspelled 40
set listsize 40
set listsize bad
set annotate bad
set annotate 6
show annotate
set annotate 1
show listsize
show annotate
#### history...
H
H 5
H 5 3
hi 11
!11
!19:p
!-3:p
!-2
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
file misc.cmd
#### info variables (V) command...
V dq*
# On OS X there is some problem in doing the above and below commands
# in succession. Further investigation is needed to fix this. 
# Until then..
## info variables dq*
quit
