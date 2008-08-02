# -*- shell-script -*-
# undisplay.cmd - gdb-like "undisplay" debugger command

#   Copyright (C) 2002, 2003, 2006, 2007, 2008 Rocky Bernstein 
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
#   with Bashdb; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

_Dbg_do_undisplay() {
  local -i del=$1

  if [ -n "${_Dbg_disp_exp[$del]}" ] ; then
    _Dbg_write_journal_eval "unset _Dbg_disp_exp[$del]"
    _Dbg_write_journal_eval "unset _Dbg_disp_enable[$del]"
  else
    _Dbg_msg "Display entry $del doesn't exist so nothing done."
  fi
}
