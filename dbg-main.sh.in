# -*- shell-script -*-
# dbg-main.sh - Bourne Again Shell Debugger Main Include

#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008, 2009 Rocky Bernstein 
#   rocky@gnu.org
#
#   bashdb is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   bashdb is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with bashdb; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

# Are we using a debugger-enabled bash? If not let's stop right here.
if [[ -z "${BASH_SOURCE[0]}" ]] ; then 
  echo "Sorry, you need to use a debugger-enabled version of bash." 2>&1
  exit 2
fi

# Stuff common to bashdb and bashdb-trace. Include the rest of options
# processing. Also includes things which have to come before other includes
. ${_Dbg_libdir}/dbg-pre.sh

# Note: "init" comes first and "cmds" has to come after "io". Otherwise 
# these are sorted alphabetically.
typeset -r _Dbg_includes='init io'

for _Dbg_file in $_Dbg_includes ; do 
  source ${_Dbg_libdir}/dbg-${_Dbg_file}.sh
done

for _Dbg_file in ${_Dbg_libdir}/lib/*.sh ; do 
    source $_Dbg_file
done

for file in ${_Dbg_libdir}/command/*.sh ; do 
  source $file
done

if [[ -r /dev/stdin ]] ; then
  _Dbg_do_source /dev/stdin
elif [[ $(tty) != 'not a tty' ]] ; then
  _Dbg_do_source $(tty)
fi

# List of command files to process
typeset -a _Dbg_input

# Have we already specified where to read debugger input from?  
#
# Note: index 0 is only set by the debugger. It is not used otherwise for
# I/O like those indices >= _Dbg_INPUT_START_DESC are.
if [ -n "$DBG_INPUT" ] ; then 
  _Dbg_input=("$DBG_INPUT")
  _Dbg_do_source "${_Dbg_input[0]}"
  _Dbg_no_init=1
fi

if [[ -z $_Dbg_no_init && -r ~/.bashdbinit ]] ; then
  _Dbg_do_source ~/.bashdbinit
fi

# _Dbg_DEBUGGER_LEVEL is the number of times we are nested inside a debugger
# by virtue of running "debug" for example.
if [[ -z "${_Dbg_DEBUGGER_LEVEL}" ]] ; then
  typeset -ix _Dbg_DEBUGGER_LEVEL=1
fi

# This is put at the so we have something at the end to stop at 
# when we debug this. By stopping at the end all of the above functions
# and variables can be tested.

if [[ ${_Dbg_libdir:0:1} == '.' ]] ; then
    # Relative file name
    _Dbg_libdir=$(_Dbg_expand_filename ${_Dbg_init_cwd}/${_Dbg_libdir})
fi

[ -n "$DBG_RESTART_FILE" ] \
   && [ -r "$DBG_RESTART_FILE" ] &&  source $DBG_RESTART_FILE
