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
_Dbg_do_quit() {
  typeset -i return_code=${1:-$_Dbg_program_exit_code}

  typeset -i desired_quit_levels=${2:-0}

  if (( desired_quit_levels == 0 \
    || desired_quit_levels > BASH_SUBSHELL+1)) ; then
    ((desired_quit_levels=BASH_SUBSHELL+1))
  fi

  ((BASHDB_QUIT_LEVELS+=desired_quit_levels))

  # Reduce the number of recorded levels that we need to leave by
  # if BASHDB_QUIT_LEVELS is greater than 0.
  ((BASHDB_QUIT_LEVELS--))

  ## write this to the next level up can read it.
  _Dbg_write_journal "BASHDB_QUIT_LEVELS=$BASHDB_QUIT_LEVELS"

  # Reset signal handlers to their default but only if 
  # we are not in a subshell.
  if (( BASH_SUBSHELL == 0 )) ; then

    # If we were told to restart from deep down, restart instead of quit.
    if [ -n "$BASHDB_RESTART_COMMAND" ] ; then 
      _Dbg_erase_journals
      _Dbg_save_state
      exec $BASHDB_RESTART_COMMAND
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
alias q=quit