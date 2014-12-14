#   Copyright (C) 2002, 2004-2008, 2011-2012 Rocky Bernstein
#   <rocky@gnu.org>
#
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation; either version 2, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; see the file COPYING.  If not, write to
#   the Free Software Foundation, 59 Temple Place, Suite 330, Boston,
#   MA 02111 USA.

AUTOMAKE_OPTIONS = dist-bzip2

SUBDIRS = command builtin init lib data doc test

pkgdata_DATA =       \
       dbg-main.sh   \
       dbg-set-d-vars.inc  \
       bashdb-main.inc     \
       bashdb-trace        \
       bashdb-part2.sh     \
       getopts_long.sh

man:
	@( cd $(top_builddir)/doc ; $(MAKE) $(MFLAGS) man )
html:
	@( cd $(top_builddir)/doc ; $(MAKE) $(MFLAGS) html )

dist: distdir

# Set up the install target. Can't figure out how to use @PACKAGE@
bin_SCRIPTS = bashdb

MOSTLYCLEANFILES = *.orig *.rej

EXTRA_DIST = bashdb.in bashdb-trace.in bashdb-main.inc.in \
	     compute-prefix.sh \
	     $(pkgdata_DATA) acinclude.m4 README.md THANKS \
	     make-check-filter.rb check-prefix.sh \
	     ChangeLog ChangeLog.0

data_DATA =

#
# This is ugly. Bash 3.0 requires things to be different than where
# many OS's would want to put bash debugger scripts or where a user
# may have asked for this to be put. It's wrong in the directory
# names it uses and for the name of the main include.
# So... using the place that configure determined bash
# wants this to be put, (BASHDB_MAIN), we try to remove any existing files
# before making a symbolic link to it. Also if was in a directory
# (containing perhaps old code), that gets removed and a symbolic link
# is added or relocated if there was another symbolic link. Finally
# the basename that bash wants to use is symlinked to the main name
# that this distribution uses dbg-main.sh, unless those are the same.
#
OLD_DIR    = $(dir @DBGR_MAIN@)
OLD_MAIN   = $(notdir @DBGR_MAIN@)
PARENT_DIR = $(dir $(OLD_DIR))
install-data-hook:
	@if test -d $(DESTDIR)$(OLD_DIR) ; then \
	     $(RM) -f $(DESTDIR)$(OLD_DIR)/* || true; \
	     $(MAKE) $(AM_MAKEFLAGS) install-pkgdataDATA; \
	else if test -L $(DESTDIR)$(OLD_DIR:/=) ; then \
	     $(RM) -f $(DESTDIR)$(OLD_DIR:/=) || true; \
	     $(MAKE) $(AM_MAKEFLAGS) install-pkgdataDATA; \
	fi; fi
	test -d $(DESTDIR)$(PKGDATADIR) || $(mkdir_p) $(DESTDIR)$(PKGDATADIR)

#: Run all tests without bloated output
check-short:
	$(MAKE) check 2>&1  | ruby @abs_top_srcdir@/make-check-filter.rb

#: Same as "check" - integration tests.
test: check

#: Unit testing
check-unit: test-unit

test-unit:
	cd test/unit && make check

#: Integration testing
test-integration:
	cd test/integration && make check

MAINTAINERCLEANFILES = ChangeLog

if MAINTAINER_MODE

#: Remove change log: ChangeLog
rmChangeLog:
	rm ChangeLog || true

#: Create ChangeLog from version control
ChangeLog: rmChangeLog
	git log --pretty --numstat --summary | $(GIT2CL) > $@

ACLOCAL_AMFLAGS=-I .

endif
