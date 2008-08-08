## Process this file with automake to produce Makefile.in -*-Makefile-*-.
#$Id: Makefile.am,v 1.27 2008/08/08 22:04:18 rockyb Exp $

SUBDIRS = unit data

check_DATA = \
	action.tests \
	brkpt1.tests \
	brkpt2.tests \
	brkpt3.tests \
	bug-args.tests \
	bug-args.sh.in \
	bug-source.tests \
	bugIFS.sh.in \
	bugIFS.tests \
	check-common.sh.in \
	command.tests \
	complete.tests \
	dbg-test1.sh \
	dbg-test1.sh.in \
	dbg-test1.sub \
	dbg-test2.sh \
	debug.sh \
	debug.tests \
	display.tests \
	finish.tests \
	frame.tests \
	hanoi.sh.in \
	interrupt.sh.in \
	interrupt.tests \
	list.tests \
	lopts.tests \
	misc.tests \
	multi.sh \
	multi1.tests \
	multi2.tests \
	multi3.tests \
	multi4.tests \
	parm.sh \
	parm.tests \
	restart.tests \
	restartbug.sh \
	search.tests \
	setshow.tests \
	settrace.sh \
	settrace.tests \
	sig.sh \
	sig.tests \
	skip.sh \
	skip.tests \
	sopts.tests \
	subshell.sh \
	subshell1.tests \
	subshell2.tests \
	subshell3.tests \
	subshell4.tests \
	tbreak.tests \
	trace.tests \
	trace2.tests \
	watch1.tests \
	watch2.tests

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

EXTRA_DIST = $(TESTS) $(check_DATA)
