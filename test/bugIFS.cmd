set trace-co on
# Debugger test of an old IFS bug
#
### Going to the location where IFS should be reset in the code...
continue 5
e _Dbg_print_source_line 5
quit

