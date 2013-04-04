test_in_files := $(wildcard test-*.in)
tests_from_in_files := $(notdir $(test_in_files:.in=))

check_DATA = \
	$(test_in_files)   \
	check-common.sh.in \
	interrupt.tests    \
	interrupt-3.tests  \
	lopts.tests        \
	settrace.tests 	   \
	sopts.tests        \
	test-sig.in        \
	trace.tests	   \
	trace2.tests

TESTS = \
	$(tests_from_in_files) \
	test-action     \
	test-brkpt      \
	test-bug-args   \
	test-bugI       \
	test-bugIFS     \
	test-bug-source \
	test-command    \
	test-complete   \
	test-display    \
	test-enable     \
	test-file-with-spaces  \
	test-finish     \
	test-frame      \
	test-interrupt  \
	test-list       \
	test-lopts 	\
	test-multi	\
	test-parm	\
	test-restart	\
	test-search	\
	test-settrace 	\
	test-skip 	\
	test-sopts 	\
	test-bug-break 	\
	test-bug-step 	\
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

MOSTLYCLEANFILES = *.orig *.rej
