#!/bin/sh
if [[ "$1"x != x ]] ; then 
  echo "passed $1"
  exit 1
fi

cmd=../example/debug.sh
../example/debug.sh $BASHDB_LEVEL
# ../../bash $cmd $x
$cmd $BASHDB_LEVEL
x=5
