# -*- shell-script -*-
# watch.cmd - gdb-like "watch" debugger command
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

_Dbg_help_add watch \
'watch [ARITH?] EXP -- Set or clear a watch expression.'

# Set or list watch command
_Dbg_do_watch() {
  if [ -z "$2" ]; then
    _Dbg_clear_watch 
  else 
    local -i n=_Dbg_watch_max++
    _Dbg_watch_arith[$n]="$1"
    shift
    _Dbg_watch_exp[$n]="$1"
    _Dbg_watch_val[$n]=$(_Dbg_get_watch_exp_eval $n)
    _Dbg_watch_enable[$n]=1
    _Dbg_watch_count[$n]=0
    _Dbg_printf '%2d: %s==%s arith: %d' $n \
      "(${_Dbg_watch_exp[$n]})" ${_Dbg_watch_val[$n]} \
    ${_Dbg_watch_arith[$n]}
  fi
}

