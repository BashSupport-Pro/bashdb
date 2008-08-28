set trace-commands on
# Test of frame commands
# We also try all of the various where/backtrace variants
# Do we give a valid stack listing initially?
# Let's start with a couple of stack entries
continue hanoi
where 2
# How about after a frame command? 
frame 0
bt 2
# How about after moving?
u
where 2
down
where 2
# Try moving past the end
down
where 2
up 3
bt 2
# Try some negative numbers
# should be the same as up
down -1
T 2
# Should go to next-to-least-recent frame
frame -2
where 2
# Let's add another stack entry
continue hanoi
where 3
# Again, next-to-least recent stack entry
frame -2
where 3
# Most recent stack entry
frame +0
backtrace 3
up 2
quit



