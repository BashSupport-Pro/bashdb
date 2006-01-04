dnl
dnl Configure script for bash-3.x debugger
dnl
dnl report bugs to rocky@panix.com
dnl
dnl Process this file with autoconf to produce a configure script.

# Copyright (C) 2002, 2003, 2004, 2005, 2006 Rocky Bernstein <rocky@panix.com>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

dnl TENTATIVE:
dnl Use same version as in main bash configure.in
define(bashvers, 3.00)
define(relstatus, 0.04cvs)

AC_INIT([bashdb],[bashvers-relstatus],[bashdb-devel@lists.sourceforge.net])

AM_PATH_LISPDIR
AM_MAINTAINER_MODE
AM_CONFIG_HEADER(config.h)
AC_REVISION([$Id: configure.ac,v 1.2 2006/01/04 19:39:51 rockyb Exp $])dnl
AC_DEFINE([PACKAGE], [bashdb], [Bash Debugger])
AC_DEFINE([VERSION], [bashvers-relstatus], [version string])

dnl make sure we are using a recent autoconf version
AC_PREREQ(2.53)

AC_ARG_PROGRAM
AM_INIT_AUTOMAKE([no-define])

AC_BASHDB_PACKAGE([bashdb])

# Brought over from bash/configure.in to substitute BASHVERS
# and RELSTATUS in dbg-pre.inc.in and version.texi
BASHVERS=bashvers
RELSTATUS=relstatus
AC_SUBST(BASHVERS)
AC_SUBST(RELSTATUS)


AC_CONFIG_SRCDIR(bashdb.in)
if test x$ac_srcdir = x ; then
  ac_srcdir=.
fi

AM_MISSING_PROG(CVS2CL, cvs2cl, $missing_dir)
AC_PROG_LN_S
AC_PATH_PROG(RM, rm, true)

AC_PATH_PROG(EMACS, emacs, no)
if test x$EMACS = xno ; then
  emacs_lisp=no
else 
  $EMACS -batch -q -no-site-file -eval \
  '(if (not (and (= emacs-major-version 21) (<= emacs-minor-version 3))) (error "This gud is for Emacs 21.0 to 21.3."))'
  if test $? -ne 0 ; then
    emacs_lisp=no
  fi
fi

dnl We use a path for perl so the #! line in autoscan will work.
AC_ARG_WITH(bash, AC_HELP_STRING([--with-bash], 
		  [location of bash 3.0 program]), BASH_PROG=$withval)

if test "$BASH_PROG" = "yes" || test "$BASH_PROG" = "no" || test -z "$BASH_PROG"
then
  AC_PATH_PROG(BASH_PROG, bash, no)
fi

if test "$BASH_PROG" = no; then
  AC_MSG_ERROR([I didn't find the bash executable.\
  You might want to use the --with-bash option.])
fi

bash_vers=`$BASH_PROG -c 'echo ${BASH_VERSINFO}'`

AC_ARG_WITH(bashdb-main, AC_HELP_STRING([--with-bashdb-main], 
		  [location of bashdb-main.inc]), BASHDB_MAIN=$withval)

dnl See if we build readarray.c
AC_ARG_WITH(bash-src, AC_HELP_STRING([--with-bash-src], 
		  [location of bash 3.0 source code]), BASH_SRC=$withval)
AC_SUBST(BASH_SRC)

dnl We run a C compiler to get macro EXEEXT set and possibly readarray.c.
AC_PROG_CC
AM_PROG_LIBTOOL
PIC=$lt_prog_compiler_pic_CXX
WL=$lt_prog_compiler_wl_CXX
AC_SUBST(PIC)
AC_SUBST(WL)

if test "$bash_vers" != 3
then
  AC_MSG_ERROR([You need bash version 3 for this debugger. I see version ${bash_vers}.])
elif test -z "$BASHDB_MAIN"
then 
  BASHDB_MAIN=`strings $BASH_PROG$EXEEXT | grep bashdb-main.inc`
  if test -z "$BASHDB_MAIN" 
  then
     AC_MSG_ERROR([I didn't find bashdb-main.inc in your bash. If you have the 
right version of bash, set it with the --with-bashdb-main option])
  fi
fi
AC_SUBST(BASHDB_MAIN)

# Create a suitable transform ( without the $ -> $$ escaping added
# because of $program_transform_name being used in a Makefile
# This transform is needed because bashbd must be executed by the
# bashdb-bash regardless if a program transform has taken place
ac_transform=`echo "$program_transform_name" | sed 's/\\$\\$/\\$/g'`

# Fully expanded name of bash executable to be substituted into
# bashdb.This allow us to move this package into any suitable location
# by using --prefix as an option to configure.
AC_SUBST_DIR(INTERPRETER_NAME,"${bindir}/"`echo bash | sed "$ac_transform"`)

# WARNING: The configure-correct name for architecture-independent
# directory (the place for the bash source for the debugger) is 
# datadir. The automake file seem to want to use pkgdatadir instead.

# I'm not sure how to get these to agree.

# Also, I'd like to set the default to the name that's been coded
# inside of the bash program rather than some autoconf standard; I
# don't know how to change the autoconf default that which is
# determined dynamically below.

# Get the fully expanded name of pkgdatadir. This is used in bashdb.in
# and dbg-main.inc.in and for installing debugger files.

pkgdatadir=$datadir/bashdb
AC_SUBST_DIR(PKGDATADIR, $pkgdatadir)

dnl We use a diff in regression testing
AC_PATH_PROG(DIFF, diff, no)
DIFF_OPTS=

if test "$DIFF" = no ; then
   AC_PATH_PROG(DIFF, cmp, no)
else 
   dnl Try for GNU diff options.
  # MSDOG output uses \r\n rather than \n in tests
  for diff_opt in -w --unified ; do 
    if $DIFF $diff_opt ./configure ./configure > /dev/null 2>&1; then
      AC_MSG_RESULT([adding $diff_opt to diff in regression tests])
      DIFF_OPTS="$DIFF_OPTS $diff_opt"
    fi
  done
fi
AC_SUBST(DIFF)
AC_SUBST(DIFF_OPTS)

AM_CONDITIONAL(INSTALL_EMACS_LISP, test "x$lispdir" != "x")

build_readarray=$BASH_SRC
if test x"$build_readarray" != x; then
   AC_CHECK_HEADERS(unistd.h string.h,,
   [AC_MSG_WARN([Missing some C headers. Disabling readarray])
   build_readarray=])
   AC_CHECK_FUNC(getline,,
   [AC_MSG_WARN([Missing GNU getline. Disabling readarray])
   build_readarray=])
fi

AM_CONDITIONAL(BUILD_READARRAY, test x"$build_readarray" != x)

#Makefiles
AC_CONFIG_FILES([Makefile \
	doc/Makefile \
	emacs/Makefile \
	test/Makefile])

# Additional files needing substitution of values (not Makefiles).
AC_CONFIG_FILES([ \
	bashdb \
	dbg-pre.inc \
	dbg-main.inc \
	test/check_common \
	doc/macros.texi \
        test/bugIFS.sh],[chmod +x bashdb])


AC_CONFIG_COMMANDS([default],[[
# Keep old dates on these files to prevent rebuilding.
touch -cr $ac_srcdir/configure.ac doc/bashdb.1
touch -cr $ac_srcdir/configure.ac doc/bashdb-man.html
if test -e $ac_srcdir/doc/version-bashdb.texi ; then
	echo timestamp > $ac_srcdir/doc/stamp-vti
	touch -cr $ac_srcdir/configure.ac $ac_srcdir/doc/version-bashdb.texi \
	$ac_srcdir/doc/stamp-vti \
	$ac_srcdir/doc/bashdb.info*
fi
]],[[]])

AC_OUTPUT

