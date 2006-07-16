#!/bin/bash
# Towers of Hanoi

init() {
  _Dbg_set_trace; : ; :
}

hanoi() { 
  local -i n=$1
  local -r a=$2
  local -r b=$3
  local -r c=$4

  if (( n > 0 )) ; then
    (( n-- ))
    hanoi $n $a $c $b
    ((disc_num=max-n))
    echo "Move disk $n on $a to $b"
    if (( n > 0 )) ; then
       hanoi $n $c $b $a
    fi
  fi
}

source ../bashdb-trace -q -L ../ -B  -x settrace.cmd
typeset -i max=3
init
hanoi $max "a" "b" "c"
