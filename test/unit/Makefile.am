## Process this file with automake to produce Makefile.in -*-Makefile-*-.
#$Id: Makefile.am,v 1.15 2008/09/07 01:28:43 rockyb Exp $

if BUILD_BUILTINS
BUILTIN_TESTS=test-set0.sh
else 
BUILTIN_TESTS=
endif

TESTS = $(BUILTIN_TESTS)     \
        test-alias.sh        \
        test-bashdb-trace.sh \
	test-columns.sh      \
        test-file.sh         \
        test-fns.sh          \
        test-frame.sh        \
        test-io.sh           \
        test-pre.sh          \
        test-run.sh          \
        test-sort.sh         \
        test-save-restore.sh

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

EXTRA_DIST = $(TESTS) shunit2 \
     test-alias.sh.in         \
     test-bashdb-trace.sh.in  \
     test-columns.sh          \
     test-file.sh.in          \
     test-fns.sh.in           \
     test-run.sh.in           \
     test-sort.sh.in          \
     test-save-restore.sh.in
