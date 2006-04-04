#   Copyright (C) 2002, 2004, 2005 Rocky Bernstein
#
#   Bash is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   Bash is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with Bash; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.
#$Id: Makefile.am,v 1.5 2006/04/04 23:23:23 rockyb Exp $

SUBDIRS = test doc emacs

if BUILD_READARRAY
bin_PROGRAMS      =  readarray
noinst_PROGRAMS   =  readarray
readarray_SOURCES =  readarray.c
readarray_CFLAGS  =  -I @BASH_SRC@ -I @BASH_SRC@/include -I@BASH_SRC@/builtins @PIC@
readarray_LDFLAGS =  -shared
readarray_builtin =  readarray
endif

man:
	@( cd $(top_builddir)/doc ; $(MAKE) $(MFLAGS) man )
html:
	@( cd $(top_builddir)/doc ; $(MAKE) $(MFLAGS) html )

# Set up the install target 
bin_SCRIPTS = bashdb

pkgdatadir=$(datadir)/bashdb

data_DATA =
pkgdata_DATA = dbg-brk.inc   dbg-cmds.inc       dbg-complete.inc \
	       dbg-file.inc  dbg-fns.inc                         \
	       dbg-help.inc  dbg-hist.inc                        \
               dbg-info.inc  dbg-init.inc       dbg-io.inc       \
               dbg-list.inc  dbg-log.inc        dbg-main.inc     \
	       dbg-pre.inc                                       \
	       dbg-set.inc   dbg-show.inc       dbg-sig.inc      \
	       dbg-stack.inc dbg-set-d-vars.inc  $(readarray_builtin)

EXTRA_DIST = dbg-pre.inc.in bashdb.in bashdb-trace.in dbg-main.inc.in \
	     $(pkgdata_DATA) acinclude.m4 THANKS \
	     ChangeLog ChangeLog.0 readarray.c

readarray$(EXEEXT): $(readarray_OBJECTS) $(readarray_DEPENDENCIES) 
	@rm -f readarray$(EXEEXT)
	$(CCLD) $(AM_CFLAGS) $(CFLAGS) $(AM_LDFLAGS) $(LDFLAGS) -o $@ \
	    $(readarray_LDFLAGS) $(readarray_OBJECTS) $(readarray_LDADD) $(LIBS)

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
# that this distribution uses dbg-main.inc, unless those are the same.
# 
OLD_DIR :=$(dir @BASHDB_MAIN@)
OLD_MAIN:=$(notdir @BASHDB_MAIN@)
PARENT_DIR:=$(dir $(OLD_DIR))
install-data-hook:
	@if test -e @BASHDB_MAIN@ ; then \
	  if test "$(OLD_MAIN)" != "dbg-main.inc" ; then \
	    $(RM) @BASHDB_MAIN@ || true; \
          fi; fi
	@if test -d $(DESTDIR)$(OLD_DIR) ; then \
	     $(RM) -fr $(DESTDIR)$(OLD_DIR:/=) || true; \
	else if test -L $(DESTDIR)$(OLD_DIR:/=) ; then \
	     $(RM) -f $(DESTDIR)$(OLD_DIR:/=) || true; \
	fi; fi
	test -d $(DESTDIR)$(PKGDATADIR) || $(mkdir_p) $(DESTDIR)$(PKGDATADIR)
	$(LN_S) $(DESTDIR)$(PKGDATADIR) $(DESTDIR)$(PARENT_DIR:/=) || true
	@if test "dbg-main.inc" != "$(OLD_MAIN)" ; then \
	  ( if cd $(DESTDIR)$(pkgdatadir) ; then \
	     test -e $(OLD_MAIN) && $(RM) $(OLD_MAIN); \
	     $(LN_S) dbg-main.inc $(OLD_MAIN) || \
	     echo "WARNING: I'm having trouble letting bash know where the debugger is. Use the bashdb script only." ; \
	  fi ) \
	fi

# cvs2cl
MAINTAINERCLEANFILES = ChangeLog

if MAINTAINER_MODE

.PHONY: ChangeLog
ChangeLog:
	$(CVS2CL) -W 450 --header $(srcdir)/cvs2cl_header --utc -w -I ChangeLog --usermap $(srcdir)/cvs2cl_usermap -P 

ACLOCAL_AMFLAGS=-I .

endif

#;;; Local Variables: ***
#;;; mode:makefile ***
#;;; End: ***
