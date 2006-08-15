#!/bin/sh
# $Id: autogen.sh,v 1.2 2006/08/15 11:09:31 myamato Exp $ 
# Run this to generate all the initial Makefiles, etc.

# Check how echo works in this /bin/sh
case `echo -n` in
-n)     _echo_n=   _echo_c='\c';;
*)      _echo_n=-n _echo_c=;;
esac

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

(test -f $srcdir/configure.ac) || {
    echo -n "*** Error ***: Directory "\`$srcdir\'" does not look like the"
    echo " top-level directory"
    exit 1
}

(echo $_echo_n " + Running aclocal: $_echo_c"; \
    aclocal -I .; \
 echo "done.")
rc=$?
(test -n $rc ) || exit $rc

(echo $_echo_n " + Running autoconf: $_echo_c"; \
    autoconf; \
 echo "done.")
rc=$?
(test -n $rc ) || exit $rc

(echo $_echo_n " + Running aclocal -I . $aclocalinclude ..."; \
  aclocal -I . $aclocalinclude; \
  if grep "^AM_CONFIG_HEADER" configure.ac >/dev/null; then \
    echo $_echo_n "Running autoheader..."; \
    autoheader; \
  fi; \
  echo "done.")

(echo $_echo_n " + Running automake: $_echo_c"; \
    automake --add-missing; \
 echo "done.")
rc=$?
(test -n $rc ) || exit $rc

touch $srcdir/doc/version.texi
test -f $srcdir/doc/stamp-vti && rm $srcdir/doc/stamp-vti
  
conf_flags="--enable-maintainer-mode" # --enable-compile-warnings #--enable-iso-c

if test x$NOCONFIGURE = x; then
  echo Running $srcdir/configure $conf_flags "$@" ...
  $srcdir/configure $conf_flags "$@" \
  && echo Now type \`make\' to compile $PKG_NAME
else
  echo Skipping configure process.
fi

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***

