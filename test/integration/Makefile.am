check_DATA = \
	check-common.sh.in \
	interrupt.tests    \
	interrupt-3.tests  \
	lopts.tests        \
	setshow.tests 	   \
	settrace.tests 	   \
	sopts.tests        \
	subshell1.tests    \
	subshell2.tests    \
	subshell3.tests    \
	subshell4.tests    \
	test-delete.in     \
	test-misc.in       \
	test-setshow.in    \
	test-sig.in        \
	trace.tests	   \
	trace2.tests

TESTS = \
	test-action     \
	test-brkpt      \
	test-bug-args   \
	test-bugI       \
	test-bugIFS     \
	test-bug-source \
	test-command    \
	test-complete   \
	test-debug      \
	test-delete     \
	test-display    \
	test-enable     \
	test-file-with-spaces  \
	test-finish     \
	test-frame      \
	test-interrupt  \
	test-list       \
	test-lopts 	\
	test-misc       \
	test-multi	\
	test-parm	\
	test-restart	\
	test-search	\
	test-setshow    \
	test-settrace 	\
	test-sig 	\
	test-skip 	\
	test-sopts 	\
	test-bug-step 	\
	test-bug-step-subshell \
	test-subshell 	\
	test-tbreak	\
	test-trace	\
	test-watch1	\
	test-watch2

TESTS_ENVIRONMENT = \
  srcdir="$(abs_srcdir)" \
  builddir="$(abs_builddir)"

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

EXTRA_DIST = $(TESTS) $(check_DATA) README

CLEANFILES = *.check

test: check
test-integration: check
