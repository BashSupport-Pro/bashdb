# -*- shell-script -*-
# quit.sh - The real way to leave this program.
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2007, 2008
#   Rocky Bernstein rocky@gnu.org
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

_Dbg_help_add quit \
'quit [EXPR] [N] -- Quit the debugger with return code EXPR.  

If EXPR is omitted, use 0. If N is given, then we terminate only 
that many subshells or nested shells.'

_Dbg_do_quit() {
  typeset -i return_code=${1:-$_Dbg_program_exit_code}

  typeset -i desired_quit_levels=${2:-0}

  if (( desired_quit_levels == 0 \
    || desired_quit_levels > BASH_SUBSHELL+1)) ; then
    ((desired_quit_levels=BASH_SUBSHELL+1))
  fi

  ((_Dbg_QUIT_LEVELS+=desired_quit_levels))

  # Reduce the number of recorded levels that we need to leave by
  # if _Dbg_QUIT_LEVELS is greater than 0.
  ((_Dbg_QUIT_LEVELS--))

  ## write this to the next level up can read it.
  _Dbg_write_journal "_Dbg_QUIT_LEVELS=$_Dbg_QUIT_LEVELS"
  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"

  # Reset signal handlers to their default but only if 
  # we are not in a subshell.
  if (( BASH_SUBSHELL == 0 )) ; then

    # If we were told to restart from deep down, restart instead of quit.
    if [ -n "$_Dbg_RESTART_COMMAND" ] ; then 
      _Dbg_erase_journals
      _Dbg_save_state
      exec $_Dbg_RESTART_COMMAND
    fi

    _Dbg_cleanup

    # Save history file
    if (( $_Dbg_history_save )) ; then
	history -w $_Dbg_histfile
    fi

    trap - DEBUG
    # This is a hack we need. I am not sure why.
    trap "_Dbg_cleanup2" EXIT
  fi

  # And just when you thought we'd never get around to it...
  exit $return_code
}

_Dbg_alias_add q quit
_Dbg_alias_add exit quit
