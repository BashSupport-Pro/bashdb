#!/bin/bash

test_is_function()
{
    _Dbg_is_function 2>&1 >/dev/null
    assertFalse 'Invalid is_function? call without a parameter' "$?"
    function foo() { echo "bar"; }
    _Dbg_is_function foo
    assertTrue 'foo should be defined' "$?"
}

# load shunit2
top_srcdir=../..
. ${top_srcdir}/lib/fns.sh
. ${top_srcdir}/command/tracefn.sh

. ./shunit2

