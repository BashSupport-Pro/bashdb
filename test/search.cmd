# Test temporary break
# $Id: search.cmd,v 1.1 2006/01/02 23:34:26 rockyb Exp $
#
p "** Try a forward search /x. Should not be the same line ..."
/x
p "** Try a backward search ?fn1? ..."
?fn1?
p "** Try another backward search ? Should not be the same line ..."
?
p "** Above search should reset list line below list start."
p "** Should get same line as line above..."
list
p "** Try forward search /fn1/. Should be line we got command before last ..."
/fn1/
p "** Try a backward search ?fn3? ..."
?fn3?
p "** Reset line back to begining ..."
list 1
p "** Try alternate search form: search /fn1/"
search /fn1/
list 1
p "** Try alternate search form: search fn3"
search fn3
p "** Try backward and forward last search..."
?
/
p "** Try alternate search form: rev fn3"
rev fn3
p "** Search for something not there..."
search foobar1111
quit

