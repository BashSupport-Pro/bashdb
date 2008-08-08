set trace-commands on
# Test to see that we read in files that mentioned in breakpoints
# but we don't step into.
continue 34
# It is important to "next" rather than "step"
next
# The following breakpoint should cause 
# a file to get read in.
break sourced_fn
info files
quit
