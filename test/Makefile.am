## Process this file with automake to produce Makefile.in -*-Makefile-*-.
#$Id: Makefile.am,v 1.10 2006/04/10 00:40:41 rockyb Exp $

check_DATA = \
	action.cmd \
	action.right \
	action.tests \
	brkpt1.cmd \
	brkpt1.right \
	brkpt1.tests \
	brkpt2.cmd \
	brkpt2.right \
	brkpt2.tests \
	brkpt3.cmd \
	brkpt3.right \
	brkpt3.tests \
	bugIFS.cmd \
	bugIFS.right \
	bugIFS.sh.in \
	bugIFS.tests \
	check_common.in \
	complete.cmd \
	complete.right \
	complete.tests \
	continue.cmd \
	dbg-test1.sh \
	dbg-test1.sub \
	dbg-test2.sh \
	debug.cmd \
	debug.right \
	debug.sh \
	debug.tests \
	debug2.cmd \
	display.cmd \
	display.right \
	display.tests \
	finish.cmd \
	finish.right \
	finish.tests \
	hanoi.sh.in \
	list.cmd \
	list.right \
	list.tests \
	lopts.right \
	lopts.tests \
	misc-output.right \
	misc.cmd \
	misc.right \
	misc.tests \
	multi.sh \
	multi1.cmd \
	multi1.right \
	multi1.tests \
	multi2.cmd \
	multi2.right \
	multi2.tests \
	multi3.cmd \
	multi3.right \
	multi3.tests \
	multi4.cmd \
	multi4.right \
	multi4.tests \
	parm.cmd \
	parm.right \
	parm.sh \
	parm.tests \
	prof1.cmd \
	prof2.cmd \
	quit.cmd \
	restart.cmd \
	restart.right \
	restart.tests \
	restart2.cmd \
	restartbug.sh \
	run-opts \
	search.cmd \
	search.right \
	search.tests \
	sig.cmd \
	sig.right \
	sig.sh \
	sig.tests \
	skip.cmd \
	skip.right \
	skip.sh \
	skip.tests \
	sopts.right \
	sopts.tests \
	subshell.sh \
	subshell1.cmd \
	subshell1.right \
	subshell1.tests \
	subshell2.cmd \
	subshell2.right \
	subshell2.tests \
	subshell3.cmd \
	subshell3.right \
	subshell3.tests \
	subshell4.cmd \
	subshell4.right \
	subshell4.tests \
	tbreak.cmd \
	tbreak.right \
	tbreak.tests \
	trace.right \
	trace.tests \
	trace2.tests \
	trace2.right \
	watch1.cmd \
	watch1.right \
	watch1.tests \
	watch2.cmd \
	watch2.right \
	watch2.tests

TESTS = run-action run-brkpt run-bugIFS run-complete run-debug run-display \
	run-finish run-list run-misc run-multi run-parm run-restart \
	run-search run-sig run-skip run-subshell run-tbreak run-trace \
	run-watch1 run-watch2

TESTS_ENVIRONMENT = \
  srcdir="$(abs_srcdir)" \
  builddir="$(abs_builddir)"

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

EXTRA_DIST = $(TESTS) $(check_DATA)
