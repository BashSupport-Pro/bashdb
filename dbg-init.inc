# -*- shell-script -*-
# dbg-init.inc - Bourne Again Shell Debugger Global Variables

#   Copyright (C) 2002, 2003, 2004, 2006, 2007, 2008 Rocky Bernstein 
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

# Note: the trend now is to move initializations which are generally
# used in only one sub-part (e.g. variables for break/watch/actions) to 
# the corresponding file.

[[ -z $_Dbg_init_ver ]] || return

typeset _cur_fn             # current function of debugged program
typeset -i _cur_line        # current line number of debugged program

# Number of statements to run before entering the debugger.
# Is used intially to get out of sourced dbg-main.inc script
# and in bashdb script to not stop in remaining bashdb statements
# before the sourcing the script to be debugged.
typeset -i _Dbg_steps=1

# Save the initial working directory so we can reset it on a restart.
typeset _Dbg_init_cwd=$(pwd)

# If called from bashdb script rather than via "bash --debugger", skip
# over some initial setup commands, like the initial "source" function
# of debugged shell script.

typeset -i _Dbg_have_set0=0
if [[ -r $_Dbg_libdir/builtin/set0 ]] ; then
  if enable -f $_Dbg_libdir/builtin/set0  set0 >/dev/null 2>&1 ; then
    _Dbg_have_set0=1
  fi
fi

typeset -r _Dbg_orig_0=$0
if [[ -n $_Dbg_script ]] ; then 
  ((_Dbg_have_set0)) && [[ -n $_source_file ]] && builtin set0 $_source_file
  _Dbg_steps=3
else 
  . ${_Dbg_libdir}/dbg-pre.inc
  [[ -z $_Dbg_source_file ]] && \
      typeset -r _Dbg_source_file=$(_Dbg_expand_filename $_Dbg_orig_0)
  typeset -i _Dbg_n=$#
  typeset -i _Dbg_i
  typeset -i _Dbg_basename_only=${BASHDB_BASENAME_ONLY:-0}
  typeset -a _Dbg_script_args
  for (( _Dbg_i=0; _Dbg_i<_Dbg_n ; _Dbg_i++ )) ; do
    _Dbg_script_args[$_Dbg_i]=$1
    shift
  done
  # Now that we've trashed the script parameters above, restore them.
  _Dbg_set_str='set --'
  for (( _Dbg_i=0; _Dbg_i<_Dbg_n ; _Dbg_i++ )) ; do
    _Dbg_set_str="$_Dbg_set_str \"${_Dbg_script_args[$_Dbg_i]}\""
  done
  eval $_Dbg_set_str
fi

typeset -i _Dbg_autoeval=0     # Evaluate unrecognized commands?
typeset -i _Dbg_listsize=10    # How many lines in a listing? 
typeset -i _Dbg_need_input=1   # True if we need to reassign input.
typeset -i _Dbg_running=1      # True we are not finished running the program
typeset -i _Dbg_currentbp=0    # If nonzero, the breakpoint number that we 
                               # are currently stopped at.
typeset last_next_step_cmd='s' # Default is step.
typeset _Dbg_stop_reason=''    # The reason we are in the debugger.
typeset _Dbg_last_print=''     # expression on last print command
typeset _Dbg_last_printe=''    # expression on last print expression command

# Sets whether or not to display command before executing it.
typeset _Dbg_trace_commands='off'

# strings to save and restore the setting of `extglob' in debugger functions
# that need it
typeset -r _seteglob='local __eopt=-u ; shopt -q extglob && __eopt=-s ; shopt -s extglob'
typeset -r _resteglob='shopt $__eopt extglob'

typeset -r int_pat="[0-9]*([0-9])"
typeset -r signed_int_pat="?([-+])+([0-9])"
typeset -r real_pat="[0-9]*([0-9]).?([0-9])*"

# Set tty to use for output. 
if [[ -z $_Dbg_tty ]] ; then 
  typeset _Dbg_tty;
  _Dbg_tty=$(tty)
  [[ $? != 0 ]] && _Dbg_tty=''
fi

# Equivalent to basename $_Dbg_orig_0 -- the short program name
typeset _Dbg_pname=${_Dbg_orig_0##*/} 

# $_Dbg_tmpdir could have been set by bashdb script rather than
# bash --debugger
typeset _Dbg_tmpdir=/tmp

# Known normal IFS consisting of a space, tab and newline
typeset -r _Dbg_space_IFS=' 	
'

# If BASHDB_QUIT_LEVELS is set to a positive number, this is the number
# of levels (subshell or shell nestings) or we should exit out of.
[[ -z $BASHDB_QUIT_LEVELS ]] && BASHDB_QUIT_LEVELS=0

# This is put at the so we have something at the end to stop at 
# when we debug this. By stopping at the end all of the above functions
# and variables can be tested.
typeset -r _Dbg_init_ver=\
'$Id: dbg-init.inc,v 1.22 2008/07/18 07:10:25 rockyb Exp $'
