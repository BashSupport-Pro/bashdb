#!/bin/sh
if [[ "$1"x != x ]] ; then 
  echo "passed $1"
  exit 1
fi

cmd=./debug.sh
./debug.sh $BASHDB_LEVEL
# ../../bash $cmd $x
$cmd $BASHDB_LEVEL
x=5
