#!../../bash
# Signal handling tests
child_handler() {
  echo "child handler called"
}

if [[ "$1"x != x ]] ; then 
  echo "child process $$ here..."
  for (( i=1; i<=1000 ; i++ )) ; do 
    x=`echo b*`
    for (( j=1; j<=1000 ; j++ )) ; do 
      x=`echo t*`
      x=`echo *source*`
    done
  done
  exit 1
fi

# set -x
x=18
# CHLD handler should not be clobbered by debugger.
trap child_handler CHLD
kill -INT $$
kill -INT $$
exit 0
