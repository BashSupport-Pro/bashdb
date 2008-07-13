# -*- shell-script -*-
# restart command.
#
#   Copyright (C) 2002, 2003, 2004, 2006, 2008 Rocky Bernstein 
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

# Restart script in same way with saved arguments (probably the same
# ones as we were given before).
_Dbg_do_restart() {

  _Dbg_cleanup;

  local script_args
  if (( $# != 0 )) ; then 
    script_args="$@"
  else
    script_args="${_Dbg_script_args[@]}"
  fi

  local exec_cmd="$_Dbg_orig_0 $script_args";
  if [[ $_Dbg_script != 1 ]] ; then
    [ -z "$BASH" ] && BASH='bash'
    if [[ $_cur_source_file == $_Dbg_bogus_file ]] ; then
      script_args="--debugger -c \"$BASH_EXECUTION_STRING\""
      exec_cmd="$BASH --debugger -c \"$BASH_EXECUTION_STRING\"";
    else
      exec_cmd="$BASH --debugger $_Dbg_orig_0 $script_args";
    fi
  elif [[ -n "$BASH" ]] ; then
      local exec_cmd="$BASH $_Dbg_orig_0 $script_args";
  fi

  if (( _Dbg_basename_only )) ; then 
    _Dbg_msg "Restarting with: $script_args"
  else
    _Dbg_msg "Restarting with: $exec_cmd"
  fi

  # If we are in a subshell we need to get out of those levels
  # first before we restart. The strategy is to write into persistent
  # storage the restart command, and issue a "quit." The quit should
  # discover the restart at the last minute and issue the restart.
  if (( BASH_SUBSHELL > 0 )) ; then 
    _Dbg_msg "Note you are in a subshell. We will need to leave that first."
    _Dbg_write_journal "BASHDB_RESTART_COMMAND=\"$exec_cmd\""
    _Dbg_do_quit 0
  fi
  _Dbg_save_state
  cd $_Dbg_init_cwd
  exec $exec_cmd
}
