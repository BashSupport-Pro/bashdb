set trace-co on
# Test bug we had where "break" wasn't clearing out the "next-over-fn" flag.
#
next
next
break fibonacci
continue
bt
delete 1
c
quit





