#!/bin/bash
# -*- shell-script -*-

test_preserve_set_opts()
{
    set -u
    old_opts=$-
    . ${top_srcdir}/bashdb-trace -L ${top_srcdir}
    assertEquals $old_opts $-
}

# load shunit2
top_srcdir=../..
. ${top_srcdir}/dbg-tracefn.inc

. ./shunit2
