set trace-commands on
#
# Test that BASH_REMATCH is saved and restored properly
#
b 7
display $BASH_REMATCH
s
c
s
c
s
c
s
c
s
c
s
c
s
c
s
c
quit
