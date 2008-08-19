## Process this file with automake to produce Makefile.in -*-Makefile-*-.
#$Id: Makefile.am,v 1.32 2008/08/19 21:32:44 rockyb Exp $

SUBDIRS = unit data example

check_DATA = \
	brkpt1.tests \
	brkpt2.tests \
	brkpt3.tests \
	bug-source.tests \
	check-common.sh.in \
	debug.sh \
	interrupt.tests \
	lopts.tests \
	multi.sh \
	parm.sh \
	restartbug.sh \
	setshow.tests \
	settrace.sh \
	settrace.tests \
	sig.sh \
	sig.tests \
	skip.sh \
	sopts.tests \
	subshell.sh \
	subshell1.tests \
	subshell2.tests \
	subshell3.tests \
	subshell4.tests \
	trace.tests \
	trace2.tests

TESTS = test-action test-brkpt test-bug-args test-bugIFS test-bug-source \
	test-command test-complete \
	test-debug test-display test-finish test-frame \
	test-list test-misc test-multi test-opts test-parm test-restart \
	test-search test-setshow test-settrace test-sig test-skip test-subshell \
        test-tbreak test-trace \
	test-watch1 test-watch2

TESTS_ENVIRONMENT = \
  srcdir="$(abs_srcdir)" \
  builddir="$(abs_builddir)"

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

EXTRA_DIST = $(TESTS) $(check_DATA) README
