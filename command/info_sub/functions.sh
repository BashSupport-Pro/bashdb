# -*- shell-script -*-
# "info functions" debugger command
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


# List display command(s)
# S [[!]pat] List Subroutine names [not] matching a pattern
# Pass along whether or not to print "system" functions?
_Dbg_do_info_functions() {

  typeset pat=$1

  typeset -a fns_a
  fns_a=($(_Dbg_get_functions 0 "$pat"))
  typeset -i i
  for (( i=0; i < ${#fns_a[@]}; i++ )) ; do
    _Dbg_msg ${fns_a[$i]}
  done
  return 0
}

