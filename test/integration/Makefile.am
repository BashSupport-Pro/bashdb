check_DATA = \
	brkpt1.tests       \
	brkpt2.tests       \
	brkpt3.tests       \
	check-common.sh.in \
	interrupt.tests    \
	interrupt-3.tests  \
	lopts.tests        \
	multi.sh           \
	setshow.tests 	   \
	settrace.tests 	   \
	sig.sh             \
	sig.tests          \
	sopts.tests        \
	subshell1.tests    \
	subshell2.tests    \
	subshell3.tests    \
	subshell4.tests    \
	trace.tests	   \
	trace2.tests

TESTS = \
	test-action     \
	test-brkpt      \
	test-bug-args   \
	test-bugIFS     \
	test-bug-source \
	test-command    \
	test-complete   \
	test-debug      \
	test-enable     \
	test-display    \
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

test: check
