## Process this file with automake to produce Makefile.in -*-Makefile-*-.
COMBINED_TESTS = $(wildcard test-*.sh)
tests_sources = $(notdir $(COMBINED_TESTS:=.in))

abs_srcdir=@abs_srcdir@
abs_builddir=@abs_builddir@

TESTS_ENVIRONMENT = \
  srcdir="$(abs_srcdir)" \
  builddir="$(abs_builddir)"

EXTRA_DIST = \
	helper.sh \
	mock-cmd.sh \
	require_me.sh \
	require_me.sh.in $(COMBINED_TESTS) shunit2 $(tests_sources)

test: check
test-unit: check

check: $(COMBINED_TESTS)
	$(SH_PROG) $(abs_srcdir)/shunit2 \
	$(abs_srcdir)/helper.sh $(abs_srcdir)/mock-cmd.sh \
	$(abs_srcdir)/require_me.sh \
	$(COMBINED_TESTS)

MOSTLYCLEANFILES = *.orig *.rej
