set trace-commands on
# Test that debugged program's signals are saved and restored across
# debug calls.
###  Testing that we have our signal set up...
info signals
###  Testing handle command...
handle TERM nostack
handle foo
handle 1000
handle TERM bogus
eval kill -TERM $$
###  Should not have printed a stack trace above...
handle TERM noprint
handle TERM stack
handle INT nostop
info signals
quit
y
