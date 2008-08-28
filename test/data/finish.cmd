set trace-commands on
# Debugger test of 'finish' command
continue fn2
where 8
finish
where 7
print $x
quit
