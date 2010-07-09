# -*- shell-script -*-
# gdb-like "info args" debugger command
#
#   Copyright (C) 2010 Rocky Bernstein rocky@gnu.org
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

# Print info args. Like GDB's "info args"
# $1 is an additional offset correction - this routine is called from two
# different places and one routine has one more additional call on top.
# This code assumes the's debugger version of
# bash where FUNCNAME is an array, not a variable.

_Dbg_do_info_args() {

  eval "$_seteglob"
  if [[ $1 != $int_pat ]] ; then 
    _Dbg_msg "Bad integer parameter: $1"
    eval "$_resteglob"
    return 1
  fi

  typeset -i i=_Dbg_stack_pos+$1

  (( i >= _Ddbg_stack_size )) && return 1

  # Figure out which index in BASH_ARGV is position "i" (the place where
  # we start our stack trace from). variable "r" will be that place.

  typeset -i q
  typeset -i r=0
  for (( q=0 ; q<i ; q++ )) ; do 
    (( r = r + ${BASH_ARGC[$q]} ))
  done

  # Print out parameter list.
  if (( 0 != ${#BASH_ARGC[@]} )) ; then

    typeset -i arg_count=${BASH_ARGC[$i]}

    ((r += arg_count - 1))

    typeset -i s
    for (( s=1; s <= arg_count ; s++ )) ; do 
      _Dbg_printf "$%d = %s" $s "${BASH_ARGV[$r]}"
      ((r--))
    done
  fi
  return 0
}

