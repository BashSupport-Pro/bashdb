## Process this file with automake to produce Makefile.in -*-Makefile-*-.
#$Id: Makefile.am,v 1.6 2008/07/16 16:02:25 rockyb Exp $

if BUILD_BUILTINS
BUILTIN_TESTS=test-set0.sh
else 
BUILTIN_TESTS=
endif

TESTS = $(BUILTIN_TESTS) \
        test-bashdb-trace.sh \
        test-fns.sh \
        test-io.sh \
        test-pre.sh \
        test-stack.sh

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

EXTRA_DIST = $(TESTS) shunit2
