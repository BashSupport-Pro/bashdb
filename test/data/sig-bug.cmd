set trace-commands on
eval kill -TERM $$
eval kill -TERM $$
continue
###  Should have printed a stack trace above...
