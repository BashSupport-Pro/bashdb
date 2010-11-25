#!/bin/bash
if (( $# > 0 )) ; then 
  echo "passed $1"
  exit 1
fi

cmd=../example/debug.sh
../example/debug.sh $_Dbg_DEBUGGER_LEVEL
# ../../bash $cmd $x
$cmd $_Dbg_DEBUGGER_LEVEL
x=5
