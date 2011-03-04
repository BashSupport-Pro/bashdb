# Make sure export command saves values
set trace-commands on
set showcommand 1
export
step
export foo
export x
c 7
set autoeval on
y=10
z=20
export y z 
c 8
x y
x z
quit
