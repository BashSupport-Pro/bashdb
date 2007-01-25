set trace-commands on
# Test 'search' command
#
###  Try a forward search /x. Should not be the same line ...
/x
###  Try a backward search ?fn1? ...
?fn1?
###  Try another backward search ? Should not be the same line ...
?
###  Above search should reset list line below list start.
###  Should get same line as line above...
list
###  Try forward search /fn1/. Should be line we got command before last ...
/fn1/
###  Try a backward search ?fn3? ...
?fn3?
###  Reset line back to begining ...
list 1
###  Try alternate search form: search /fn1/
search /fn1/
list 1
###  Try alternate search form: search fn3
search fn3
###  Try backward and forward last search...
?
/
###  Try alternate search form: rev fn3
rev fn3
###  Search for something not there...
search foobar1111
quit

