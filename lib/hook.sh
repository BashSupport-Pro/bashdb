# -*- shell-script -*-
# hook.sh - Debugger trap hook
#
#   Copyright (C) 2002, 2003, 2004, 2006, 2007, 2008, 2009 Rocky Bernstein 
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

typeset _Dbg_RESTART_COMMAND=''

# This is set to 1 if you want to debug debugger routines, i.e. routines
# which start _Dbg_. But you better should know what you are doing
# if you do this or else you may get into a recursive loop.
typeset -i _Dbg_debug_debugger=0

typeset _Dbg_stop_reason=''    # The reason we are in the debugger.

# Set to 0 to clear "trap DEBUG" after entry
typeset -i _Dbg_restore_debug_trap=1

# ===================== FUNCTIONS =======================================

# We come here after before statement is run. This is the function named
# in trap SIGDEBUG.

# Note: We have to be careful here in naming "local" variables. In contrast
# to other places in the debugger, because of the read/eval loop, they are
# in fact seen by those using the debugger. So in contrast to other "local"s
# in the debugger, we prefer to preface these with _Dbg_.

_Dbg_debug_trap_handler() {

  ### The below is also copied below in _Dbg_sig_handler...
  ### Should put common stuff into a function.

  # Consider putting the following line(s) in a routine.
  # Ditto for the restore environment
  typeset -i _Dbg_debugged_exit_code=$?
  _Dbg_old_set_opts=$-
  shopt -s extdebug

  # Turn off line and variable trace listing if were not in our own debug
  # mode, and set our own PS4 for debugging inside the debugger
  (( !_Dbg_debug_debugger )) && set +x +v +u

  # If we are in our own routines -- these start with _bashdb -- then
  # return.
  if [[ ${FUNCNAME[1]} == _Dbg_* ]] && ((  !_Dbg_debug_debugger )); then
    _Dbg_set_to_return_from_debugger 0
    return 0
  fi

  _Dbg_set_debugger_entry

  typeset -i _Dbg_rc=0

  # Shift off "RETURN";  we do not need that any more.
  shift 

  _Dbg_bash_command=$1
  shift

  # Save values of $1 $2 $3 when debugged program was stopped
  # We use the loop below rather than _Dbg_set_args="(@)" because
  # we want to preserve embedded blanks in the arguments.
  typeset -i _Dbg_n=${#@}
  typeset -i _Dbg_i
  typeset -i _Dbg_arg_max=${#_Dbg_arg[@]}

  # If there has been a shift since the last time we entered,
  # it is possible that _Dbg_arg will contain too many values.
  # So remove those that have disappeared.
  for (( _Dbg_i=_Dbg_arg_max; _Dbg_i > _Dbg_n ; _Dbg_i-- )) ; do
      unset _Dbg_arg[$_Dbg_i]
  done
 
  # Populate _Dbg_arg with $1, $2, etc.
  for (( _Dbg_i=1 ; _Dbg_n > 0; _Dbg_n-- )) ; do
    _Dbg_arg[$_Dbg_i]=$1
    ((_Dbg_i++))
    shift
  done
  unset _Dbg_arg[0]       # Get rid of line number; makes array count
                          # correct; also listing all _Dbg_arg works
                          # like $*.

  # if in step mode, decrement counter
  if ((_Dbg_step_ignore > 0)) ; then 
    ((_Dbg_step_ignore--))
    _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"
  fi

  # look for watchpoints.
  typeset -i _Dbg_i
  for (( _Dbg_i=0; _Dbg_i < _Dbg_watch_max ; _Dbg_i++ )) ; do
    if [ -n "${_Dbg_watch_exp[$_Dbg_i]}" ] \
      && [[ ${_Dbg_watch_enable[_Dbg_i]} != 0 ]] ; then
      typeset new_val=`_Dbg_get_watch_exp_eval $_Dbg_i`
      typeset old_val=${_Dbg_watch_val[$_Dbg_i]}
      if [[ $old_val != $new_val ]] ; then
	((_Dbg_watch_count[_Dbg_i]++))
	_Dbg_msg "Watchpoint $_Dbg_i: ${_Dbg_watch_exp[$_Dbg_i]} changed:"
	_Dbg_msg "  old value: '$old_val'"
	_Dbg_msg "  new value: '$new_val'"
	_Dbg_print_location_and_command
	_Dbg_watch_val[$_Dbg_i]=$new_val
	_Dbg_process_commands
	_Dbg_set_to_return_from_debugger 1
	return $_Dbg_rc
      fi
    fi
  done

  # Run applicable action statement
  typeset entries=`_Dbg_get_assoc_array_entry "_Dbg_action_$_cur_filevar" $_curline`
  if [[ $entries != "" ]]  ; then
    typeset -i _Dbg_i
    for _Dbg_i in $entries ; do
      if [[ ${_Dbg_action_enable[_Dbg_i]} != 0 ]] ; then
	. ${_Dbg_libdir}/dbg-set-d-vars.inc
	eval "${_Dbg_action_stmt[$_Dbg_i]}"
      fi
    done
  fi

  # check if breakpoint reached
  typeset -r entries=`_Dbg_get_assoc_array_entry "_Dbg_brkpt_$_cur_filevar" $_curline`
  if [[ $entries != "" ]]  ; then
    typeset -i _Dbg_i
    for _Dbg_i in $entries ; do
      if [[ ${_Dbg_brkpt_enable[_Dbg_i]:0} != 0 ]] ; then
	typeset -i cond
	. ${_Dbg_libdir}/dbg-set-d-vars.inc
	eval let cond=${_Dbg_brkpt_cond[$_Dbg_i]:0}
	if [[ $cond != 0 ]] ; then
	  ((_Dbg_brkpt_count[_Dbg_i]++))
	  if [[ ${_Dbg_brkpt_onetime[_Dbg_i]:0} == 1 ]] ; then
	    _Dbg_stop_reason='at a breakpoint that has since been deleted'
	    _Dbg_delete_brkpt_entry $_Dbg_i
	  else
	    _Dbg_brkpt_num=$_Dbg_i
	     _Dbg_stop_reason="at breakpoint $_Dbg_brkpt_num"
	    _Dbg_msg \
              "Breakpoint $_Dbg_i hit (${_Dbg_brkpt_count[$_Dbg_i]} times)."
	  fi
	  # We're sneaky and check commands_end because start could 
	  # legitimately be 0.
	  if (( ${_Dbg_brkpt_commands_end[$_Dbg_i]} )) ; then
	      # Run any commands associated with this breakpoint
	      _Dbg_bp_commands $_Dbg_i
	  fi
	  _Dbg_print_location_and_command
	  _Dbg_process_commands		# enter debugger
	  _Dbg_set_to_return_from_debugger 1
	  return $_Dbg_rc
	fi
      fi

    done
  fi

  # Check if step mode and number steps to ignore.
  if ((_Dbg_step_ignore == 0)); then

      if ((_Dbg_step_force)) ; then
	  if (( $_Dbg_last_lineno == $_curline )) \
	      && [[ $_Dbg_last_source_file == $_Dbg_frame_last_filename ]] ; then 
	      _Dbg_set_to_return_from_debugger 1
	      return $_Dbg_rc
	  fi
      fi

    _Dbg_print_location_and_command

    _Dbg_stop_reason='after being stepped'
    _Dbg_process_commands		# enter debugger
    _Dbg_set_to_return_from_debugger 1
    return $_Dbg_rc
  elif (( ${#FUNCNAME[@]} == _Dbg_return_level )) ; then
    # here because a trap RETURN
    _Dbg_stop_reason='on a return'
    _Dbg_return_level=0
    _Dbg_print_location_and_command
    _Dbg_process_commands		# enter debugger
    _Dbg_set_to_return_from_debugger 1
    return $_Dbg_rc
  elif (( -1 == _Dbg_return_level )) ; then
    # here because we are fielding a signal.
    _Dbg_stop_reason='on fielding signal'
    _Dbg_print_location_and_command
    _Dbg_process_commands		# enter debugger
    _Dbg_set_to_return_from_debugger 1
    return $_Dbg_rc
  elif ((_Dbg_linetrace==1)) ; then 
    if ((_Dbg_linetrace_delay)) ; then
	sleep $_Dbg_linetrace_delay
    fi
    _Dbg_print_linetrace
  fi
  _Dbg_set_to_return_from_debugger 1
  return $_Dbg_inside_skip
}

# Cleanup routine: erase temp files before exiting.
_Dbg_cleanup() {
    rm $_Dbg_evalfile 2>/dev/null
    set +u
    if [[ -n $_Dbg_EXECUTION_STRING ]] && [[ -r $_Dbg_script_file ]] ; then
	rm $_Dbg_script_file
    fi
    _Dbg_erase_journals
    _Dbg_restore_user_vars
}

# Somehow we can't put this in _Dbg_cleanup and have it work.
# I am not sure why.
_Dbg_cleanup2() {
  _Dbg_erase_journals
  trap - EXIT
}

