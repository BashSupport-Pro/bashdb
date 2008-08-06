# -*- shell-script -*-
# stepping.cmd - Bourne Again Shell Debugger step/next logging
#
#   Copyright (C) 2006, 2008 Rocky Bernstein rocky@gnu.org
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

# Sets whether or not to display command to be executed in debugger prompt.
# If yes, always show. If auto, show only if the same line is to be run
# but the command is different.

_Dbg_do_next_step_skip() {

  if (( ! _Dbg_running )) ; then
      _Dbg_msg "The program is not being run."
      return
  fi

  local cmd=$1
  local count=${2:-1}
  # Do we step debug into functions called or not?
  if [[ $cmd == n* ]] ; then
    _Dbg_old_set_opts="$_Dbg_old_set_opts +o functrace"
  else
    _Dbg_old_set_opts="$_Dbg_old_set_opts -o functrace"
  fi
  _Dbg_write_journal "_Dbg_old_set_opts=\"$_Dbg_old_set_opts\""

  if [[ $count == [0-9]* ]] ; then
    let _Dbg_step_ignore=${count:-1}
  else
    _Dbg_msg "Argument ($count) should be a number or nothing."
    _Dbg_step_ignore=1
  fi
  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"
}

