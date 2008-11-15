# -*- shell-script -*-
# delete.sh - gdb-like "delete" debugger command
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008 Rocky Bernstein
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

_Dbg_help_add delete \
"delete {BRKPT-NUM}... -- Delete the breakpoint entry or entries.
With no BRKPT-NUM, delete all breakpoints."

# Routine to a delete breakpoint/watchpoint by entry numbers.
_Dbg_do_delete() {
  typeset to_go; to_go=$@
  typeset -i  i
  typeset -i  tot_found=0
  
  eval "$_seteglob"
  for del in $to_go ; do 
    case $del in
      $_watch_pat )
        _Dbg_delete_watch_entry ${del:0:${#del}-1}
        ;;
      $int_pat )
	_Dbg_delete_brkpt_entry $del
        ((tot_found += $?))
	;;
      * )
	_Dbg_errmsg "Invalid entry number skipped: $del"
    esac
  done
  eval "$_resteglob"
  (( tot_found != 0 )) && _Dbg_msg "Removed $tot_found breakpoint(s)."
  return $tot_found
}

