#!../../bash

fn1() {
  x="fn1 started"
  if (( $1 == 0 )) ; then
    fn2 "testing 1" "2 3"
    return
  fi
  let a=$1-1
  fn1 $a 
  x="fn1 returning"
}

fn2() {
  x="fn2 started"
  echo "fn2: $1 $2"
  fn3
  x="fn2 returning"
}

fn3() {
  echo "fn3: $1 $2"
  x="fn3 returning"
}

x="main"
fn1 5
echo "exit 5" | bash
exit 0
#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
