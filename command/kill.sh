# -*- shell-script -*-
# kill.sh - gdb-like "kill" debugger command
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

_Dbg_help_add kill \
"kill [SIGNAL]	-- Kill execution of program being debugged.

If given, SIGNAL should be start with a '-', .e.g. -TERM or -9, and that
signal is used in the kill command."

_Dbg_do_kill() {
  if (($# > 1)); then
      _Dbg_errmsg "Got $# parameters, but need 0 or 1."
      return 1
  fi
  typeset _Dbg_prompt_output=${_Dbg_tty:-/dev/null}
  local signal='-9'
  (($# == 1)) && signal="$1"

  if [[ ${signal:0:1} != '-' ]] ; then
      _Dbg_errmsg "Kill signal ($signal} should start with a '-'"
      return 1
  fi
      
  read $_Dbg_edit -p "Do hard kill and terminate the debugger? (y/n): " \
      <&$_Dbg_input_desc 2>>$_Dbg_prompt_output

  if [[ $REPLY = [Yy]* ]] ; then 
      kill $signal $$
  fi
  return 0
}
