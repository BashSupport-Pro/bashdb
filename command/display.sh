# -*- shell-script -*-
# display.sh - gdb-like "(un)display" and list display debugger commands
#
#   Copyright (C) 2002, 2003, 2006, 2007, 2008, 2009 Rocky Bernstein 
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

_Dbg_help_add display \
"display [EXP] -- Set display expression or list all display expressions."

# Set display command or list all current display expressions
_Dbg_do_display() {
  if (( 0 == $# )); then
    _Dbg_eval_all_display
  else 
    local -i n=_Dbg_disp_max++
    _Dbg_disp_exp[$n]="$@"
    _Dbg_disp_enable[$n]=1
    _Dbg_printf '%2d: %s' $n "${_Dbg_disp_exp[$n]}"
  fi
}

# List display command(s)
_Dbg_do_list_display() {
  if [ ${#_Dbg_disp_exp[@]} != 0 ]; then
    local i=0 j
    _Dbg_msg "Display expressions:"
    _Dbg_msg "Num Enb Expression          "
    for (( i=0; i < _Dbg_disp_max; i++ )) ; do
      if [ -n "${_Dbg_disp_exp[$i]}" ] ;then
	_Dbg_printf '%-3d %3d %s' \
	  $i ${_Dbg_disp_enable[$i]} "${_Dbg_disp_exp[$i]}"
      fi
    done
  else
    _Dbg_msg "No display expressions have been set."
  fi
}

_Dbg_help_add undisplay \
"undisplay [EXP]	- Set display expression or list all display expressions."

_Dbg_do_undisplay() {
  local -i del=$1

  if [ -n "${_Dbg_disp_exp[$del]}" ] ; then
    _Dbg_write_journal_eval "unset _Dbg_disp_exp[$del]"
    _Dbg_write_journal_eval "unset _Dbg_disp_enable[$del]"
  else
    _Dbg_msg "Display entry $del doesn't exist so nothing done."
  fi
}
