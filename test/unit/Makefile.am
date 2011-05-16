## Process this file with automake to produce Makefile.in -*-Makefile-*-.
COMBINED_TESTS = $(wildcard test-*.sh)
TESTS_SOURCES = $(notdir $(COMBINED_TESTS:=.in))

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

TESTS_ENVIRONMENT = \
  srcdir="$(abs_srcdir)" \
  builddir="$(abs_builddir)"

EXTRA_DIST = helper.sh require_me.sh.in $(COMBINED_TESTS) shunit2 $(TEST_SOURCES)

test: check
test-unit: check

check: $(COMBINED_TESTS)
	$(SH_PROG) $(abs_srcdir)/shunit2 $(COMBINED_TESTS)

MOSTLYCLEANFILES = *.orig *.rej
