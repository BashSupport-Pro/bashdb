set trace-commands on
set showcommand on
### Test partial quit inside multi-statement line...
step 
step
### Next step should bring us inside a subshell. Test from there...
step 2
quit 0 1
quit
