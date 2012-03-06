set trace-co on
# Test bug we had where "step" wasn't clearing out the "next-over-fn" flag.
#
next
step
step
quit
