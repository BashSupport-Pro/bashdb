# dbg-sig-ret.inc - Bourne Again Shell Debugger Signal handling routines
#
#   Copyright (C) 2002, 2003, 2004 Rocky Bernstein
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

if [[ $_Dbg_old_ERR_handler != '' ]] ; then
  eval $_Dbg_old_ERR_handler
else 
 trap '' ERR
fi

## Should make sure we are not using our own return handler...
#if [[ $_Dbg_old_RETURN_handler != '' ]] ; then
#  eval $_Dbg_old_RETURN_handler
#else 
#  trap '' RETURN
#fi

if [[ $_Dbg_old_INT_handler != '' ]] ; then
  eval $_Dbg_old_INT_handler
else 
  trap '' INT
fi

# if [[ $_Dbg_old_EXIT_handler != '' ]] ; then
#   eval $_Dbg_old_EXIT_handler
# else 
#   trap '' EXIT
# fi

local _Dbg_old_IFS="$IFS"
IFS="$_Dbg_space_IFS";
set -$_Dbg_old_set_opts
IFS="$_Dbg_old_IFS";

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
