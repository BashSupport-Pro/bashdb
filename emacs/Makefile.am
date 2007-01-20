#   Copyright (C) 2002, 2003, 2006 Rocky Bernstein rocky@panix.com
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
#$Id: Makefile.am,v 1.5 2007/01/20 12:02:03 rockyb Exp $

check_DATA := bashdb-test.el bashdb-test.el.in elk-test.el
EXTRA_DIST := bashdb.el $(check_DATA)
ELCFILES  :=  bashdb.elc
if INSTALL_EMACS_LISP
lisp_LISP := bashdb.el
endif

test: check

check:
	$(EMACS) -batch -q -l $(top_builddir)/emacs/bashdb-test.el $(srcdir)/elk-test.el


