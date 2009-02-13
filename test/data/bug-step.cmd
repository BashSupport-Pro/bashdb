set trace-co on
# Test bug we had where "step" wasn't clearing out the "next" flag.
#
next
step
step
quit
