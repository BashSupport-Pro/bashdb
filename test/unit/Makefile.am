## Process this file with automake to produce Makefile.in -*-Makefile-*-.
#$Id: Makefile.am,v 1.8 2008/08/06 23:27:29 rockyb Exp $

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
        test-run.sh \
        test-stack.sh

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

EXTRA_DIST = $(TESTS) shunit2 \
     test-fns.sh.in test-run.sh.in test-tracefn.sh.in test-basdhb-trace.in
