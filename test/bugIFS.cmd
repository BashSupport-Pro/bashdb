set trace-co on
# Debugger test of an old IFS bug
#
### Going to the location where IFS should be reset in the code...
continue 5
e _Dbg_print_source_line 5
step
## Make sure IFS in an eval is the same as what we just set.
eval declare -p IFS
step 2
## Make sure PS4 in an eval is the same as what we just set.
eval declare -p PS4
quit

