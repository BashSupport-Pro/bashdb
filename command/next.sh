# -*- shell-script -*-
# gdb-like "next" (step over) and skip commmands.
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

# Sets whether or not to display command to be executed in debugger prompt.
# If yes, always show. If auto, show only if the same line is to be run
# but the command is different.

_Dbg_help_add next \
"next [COUNT]	-- Single step an statement skipping functions.

If COUNT is given, stepping occurs that many times before
stopping. Otherwise COUNT is one. COUNT an be an arithmetic
expression.

Functions and source'd files are not traced. This is in contrast to 
\"step\". See also \"skip\"."

_Dbg_help_add skip \
"skip [COUNT]	-- Skip (don't run) the next COUNT command(s).

If COUNT is given, stepping occurs that many times before
stopping. Otherwise COUNT is one. COUNT an be an arithmetic
expression. See also \"next\" and \"step\"."

_Dbg_do_next_skip() {

  _Dbg_not_running && return 1

  local cmd=$1
  local count=${2:-1}
  # Do we step debug into functions called or not?
  if [[ $cmd == n* ]] ; then
    _Dbg_old_set_opts="$_Dbg_old_set_opts +o functrace"
  else
    _Dbg_old_set_opts="$_Dbg_old_set_opts -o functrace"
  fi
  _Dbg_write_journal_eval "_Dbg_old_set_opts='$_Dbg_old_set_opts'"

  if [[ $count == [0-9]* ]] ; then
    let _Dbg_step_ignore=${count:-1}
  else
    _Dbg_errmsg "Argument ($count) should be a number or nothing."
    _Dbg_step_ignore=1
  fi
  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"
}

_Dbg_alias_add 'n'  'next'
