# -*- shell-script -*-
# dbg-processor.sh - Bourne Again Shell Debugger Top-level debugger commands
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009
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

# Debugger command loop: Come here at to read debugger commands to
# run.

# Main-line debugger read/execute command loop

# ==================== VARIABLES =======================================
# _Dbg_INPUT_START_DESC is the lowest descriptor we use for reading.
# _Dbg_MAX_INPUT_DESC   is the maximum input descriptor that can be 
#                       safely used (as per the bash manual on redirection)
# _Dbg-input_desc       is the current descriptor in use. "sourc"ing other
#                       command files will increase this descriptor
typeset -ir _Dbg_INPUT_START_DESC=4
typeset -i  _Dbg_MAX_INPUT_DESC=9  # logfile can reduce this
typeset -i  _Dbg_input_desc=_Dbg_INPUT_START_DESC-1 # will ++ before use

# Return code to indicated the next command should be skipped.
typeset -i  _Dbg_inside_skip=0

# keep a list of source'd command files. If the entry is "" then we are 
# interactive.
typeset -a _Dbg_cmdfile=('')

# A variable holding a space is set so it can be used in a "set prompt" command
# ("read" in the main command loop will remove a trailing space so we need
# another way to allow a user to enter spaces in the prompt.)

typeset _Dbg_space=' '

# Should we allow editing of debugger commands? 
# The value should either be '-e' or ''. And if it is
# on, the edit style indicates what style edit keystrokes.
typeset _Dbg_edit='-e'
typeset _Dbg_edit_style='emacs'  # or vi
set -o $_Dbg_edit_style

# What do we use for a debugger prompt? Technically we don't need to
# use the above $bashdb_space in the assignment below, but we put it
# in to suggest to a user that this is how one gets a spaces into the
# prompt.

typeset _Dbg_prompt_str='bashdb${_Dbg_less}${#_Dbg_history[@]}${_Dbg_greater}$_Dbg_space'

# The arguments in the last "x" command.
typeset _Dbg_last_x_args=''

# The canonical name of last command run.
typeset _Dbg_last_cmd=''

# ===================== FUNCTIONS =======================================

# Note: We have to be careful here in naming "local" variables. In contrast
# to other places in the debugger, because of the read/eval loop, they are
# in fact seen by those using the debugger. So in contrast to other "local"s
# in the debugger, we prefer to preface these with _Dbg_.
function _Dbg_process_commands {

  # THIS SHOULD BE DONE IN dbg-sig.sh, but there's a bug in BASH in 
  # trying to change "trap RETURN" inside a "trap RETURN" handler....
  # Turn off return trapping. Not strictly necessary, since it *should* be 
  # covered by the _Dbg_ test below if we've named functions correctly.
  # However turning off the RETURN trap should reduce unnecessary calls.
  # trap RETURN  

  _Dbg_inside_skip=0
  _Dbg_step_ignore=-1  # Nuke any prior step ignore counts
  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"

  # Evaluate all the display expressions
  _Dbg_eval_all_display

  # Loop over all pending open input file descriptors
  while (( $_Dbg_input_desc >= $_Dbg_INPUT_START_DESC )) ; do

    # Set up prompt to show shell and subshell levels.
    typeset _Dbg_greater=''
    typeset _Dbg_less=''
    typeset result  # Used by copies to return a value.
    
    if _Dbg_copies '>' $_Dbg_DEBUGGER_LEVEL ; then
	_Dbg_greater=$result
	_Dbg_less=${result//>/<}
    fi
    if _Dbg_copies ')' $BASH_SUBSHELL ; then
	_Dbg_greater="${result}${_Dbg_greater}"
	_Dbg_less="${_Dbg_less}${result//)/(}"
    fi

    # Loop over debugger commands. But before reading a debugger
    # command, we need to make sure IFS is set to spaces to ensure our
    # two variables (command name and rest of the arguments) are set
    # correctly.  Saving the IFS and setting it to the "normal" value
    # of space should be done in the DEBUG signal handler entry.

    # Also, we need to make sure the prompt output is
    # redirected to the debugger terminal.  Both of these things may
    # have been changed by the debugged program for its own
    # purposes. Furthermore, were we *not* to redirect our stderr
    # below, we may mess up what the debugged program expects to see
    # in in stderr by adding our debugger prompt.

    # if no tty, no prompt
    local _Dbg_prompt_output=${_Dbg_tty:-/dev/null}

    eval "local _Dbg_prompt=$_Dbg_prompt_str"
    _Dbg_preloop

    local _Dbg_cmd 
    local args
    local rc

    while : ; do 
	set -o history
	if ! read $_Dbg_edit -p "$_Dbg_prompt" _Dbg_cmd args \
	    <&$_Dbg_input_desc 2>>$_Dbg_prompt_output ; then
	    set +o history
	    break
	fi
	set +o history
        if (( _Dbg_brkpt_commands_defining )) ; then
	  case $_Dbg_cmd in
	      silent ) 
		  _Dbg_brkpt_commands_silent[$_Dbg_brkpt_commands_current]=1
		  continue
		  ;;
	      end )
		  _Dbg_brkpt_commands_defining=0
		  #### ??? TESTING
		  ## local -i cur=$_Dbg_brkpt_commands_current
		  ## local -i start=${_Dbg_brkpt_commands_start[$cur]}
		  ## local -i end=${_Dbg_brkpt_commands_end[$cur]}
		  ## local -i i
		  ## echo "++ brkpt: $cur, start: $start, end: $end "
		  ## for (( i=start; (( i < end )) ; i++ )) ; do
		  ##    echo ${_Dbg_brkpt_commands[$i]}
		  ## done
		  eval "_Dbg_prompt=$_Dbg_prompt_str"
		  continue
		  ;;
	      *) 
		  _Dbg_brkpt_commands[${#_Dbg_brkpt_commands[@]}]="$_Dbg_cmd $args"
		  (( _Dbg_brkpt_commands_end[$_Dbg_brkpt_commands_current]++ ))
		  continue
		  ;;
	 esac
	 rc=$?
     else
	_Dbg_onecmd "$_Dbg_cmd" "$args"
	rc=$?
	_Dbg_postcmd
    fi
    if (( $rc != 10 )) ; then 
       return $rc
    fi
    if (( _Dbg_brkpt_commands_defining )) ; then
       _Dbg_prompt='>'
    else
       eval "_Dbg_prompt=$_Dbg_prompt_str"
    fi

    done  # while read $_Dbg_edit -p ...

    ((_Dbg_input_desc--))

    # Remove last entry of $_Dbg_cmdfile
    unset _Dbg_cmdfile[${#_Dbg_cmdfile[@]}]

  done  # Loop over all open pending file descriptors

  # EOF hit. Same as quit without arguments
  _Dbg_msg '' # Cause <cr> since EOF may not have put in.
  _Dbg_do_quit
}

# Run a debugger command "annotating" the output
_Dbg_annotation() {
  local label=$1
  shift
  _Dbg_do_print "$label"
  $*
  _Dbg_do_print  ''
}

# Run a single command
# Parameters: _Dbg_cmd and args
# 
_Dbg_onecmd() {

    typeset full_cmd=$@
    typeset expanded_alias; _Dbg_alias_expand "$1"
    typeset _Dbg_cmd="$expanded_alias"
    # typeset _Dbg_cmd="$1"
    shift
    typeset args="$@"

     # Set default next, step or skip command
     if [[ -z $_Dbg_cmd ]]; then
	_Dbg_cmd=$_Dbg_last_next_step_cmd
	args=$_Dbg_last_next_step_args
	full_cmd="$_Dbg_cmd $args"
      fi

     # If "set trace-commands" is "on", echo the the command
     if [[  $_Dbg_trace_commands == 'on' ]]  ; then
       _Dbg_msg "+$full_cmd"
     fi

     local dq_cmd=$(_Dbg_esc_dq "$_Dbg_cmd")
     local dq_args=$(_Dbg_esc_dq "$args")

     # _Dbg_write_journal_eval doesn't work here. Don't really understand
     # how to get it to work. So we do this in two steps.
     _Dbg_write_journal \
        "_Dbg_history[${#_Dbg_history[@]}]=\"$dq_cmd $dq_args\""

     _Dbg_history[${#_Dbg_history[@]}]="$_Dbg_cmd $args"

     _Dbg_hi=${#_Dbg_history[@]}
     history -s -- "$full_cmd"

      local -i _Dbg_redo=1
      while (( $_Dbg_redo )) ; do

	_Dbg_redo=0

      case $_Dbg_cmd in

	# Comment line
	[#]* ) 
	  _Dbg_history_remove_item
	  _Dbg_last_cmd='#'
	  ;;

	# List window up to _curline
	- )
	  typeset -i start_line=(_curline+1-$_Dbg_listsize)
	  typeset -i count=($_Dbg_listsize)
	  if (( start_line <= 0 )) ; then
	    ((count=count+start_line-1))
	    start_line=1
	  fi
	  _Dbg_list $_Dbg_frame_last_filename $start_line $count
	  _Dbg_last_cmd='list'
	  ;;

	# list current line
	. )
	  _Dbg_list $_Dbg_frame_last_filename $_curline 1
	  _Dbg_last_cmd='list'
	  ;;

	# Search forwards for pattern
	/* )
	  _Dbg_do_search $_Dbg_cmd
	  _Dbg_last_cmd='search'
	  ;;

	# Search backwards for pattern
	[?]* )
	  _Dbg_do_search_back $_Dbg_cmd
	  _Dbg_last_cmd="search"
	  ;;

	# Set action to be silently run when a line is hit
	a )
	  _Dbg_do_action $args 
	  _Dbg_last_cmd='action'
         ;;

	# Add a debugger command alias
	alias )
	  _Dbg_do_alias $args 
	  _Dbg_last_cmd='alias'
         ;;

	# Set breakpoint on a line
	break )
	  _Dbg_do_break 0 $args 
	  _Dbg_last_cmd='break'
	  ;;

	# Continue
	continue )
	  
	  _Dbg_last_cmd='continue'
	  if _Dbg_do_continue $args ; then
	    _Dbg_write_journal_eval \
	      "_Dbg_old_set_opts='$_Dbg_old_set_opts -o functrace'"
	    return 0
	  fi
	  ;;

	# Change Directory
	cd )
	  # Allow for tilde expansion. We also allow expansion of
	  # variables like $HOME which gdb doesn't allow. That's life.
	  local cd_command="cd $args"
	  eval $cd_command
	  _Dbg_do_pwd
	  _Dbg_last_cmd='cd'
	  ;;

	# commands
	comm | comma | comman | command | commands )
	  _Dbg_do_commands $args
	  _Dbg_last_cmd='commands'
	  ;;

	# complete
	com | comp | compl | comple |complet | complete )
	  _Dbg_do_complete $args
	  _Dbg_last_cmd='complete'
	  ;;

	# Breakpoint/Watchpoint Conditions
	cond | condi |condit |conditi | conditio | condition )
	  _Dbg_do_condition $args
	  _Dbg_last_cmd='condition'
	  ;;

	# Delete all breakpoints by line number.
	# Note we use "d" as an alias for "clear" to be compatible
	# with the Perl5 debugger.
	d | cl | cle | clea | clea | clear )
	  _Dbg_do_clear_brkpt $args
	  _Dbg_last_cmd='clear'
	  ;;

	# Delete breakpoints by entry numbers. Note "d" is an alias for
	# clear.
	de | del | dele | delet | delete )
	  _Dbg_do_delete $args
	  _Dbg_last_cmd='delete'
	  ;;

	# Set up a script for debugging into.
	debug )
	  _Dbg_do_debug $args
	  # Skip over the execute statement which presumably we ran above.
	  _Dbg_do_next_skip 'skip' 1
	  IFS="$_Dbg_old_IFS";
	  return 1
	  _Dbg_last_cmd='debug'
	  ;;

	# Disable breakpoints
	di | dis | disa | disab | disabl | disable )
	  _Dbg_do_disable $args
	  _Dbg_last_cmd='disable'
	  ;;

	# Display expression
	disp | displ | displa| display )
	  _Dbg_do_display $args
	  ;;

	# Delete all breakpoints.
	D | deletea | deleteal | deleteall )
	  _Dbg_clear_all_brkpt
	  _Dbg_last_cmd='deleteall'
	  ;;

	# Move call stack down
	down )
	  _Dbg_do_down $args
	  _Dbg_last_cmd='down'
	  ;;

	# edit file currently positioned at
	edit )
	  _Dbg_do_edit $args
	  _Dbg_last_cmd='edit'
	  ;;

	# enable a breakpoint or watchpoint
	en | ena | enab | enabl | enable )
	  _Dbg_do_enable $args
	  _Dbg_last_cmd='enable'
	  ;;

	# evaluate a shell command
	eval )
	  _Dbg_do_eval $args
	  _Dbg_last_cmd='eval'
	  
	  ;;

	# intelligent print of variable, function or expression
	examine )
	  _Dbg_do_examine "$args"
	  ;;

	# 
	file )
	  _Dbg_do_file $args
	  _Dbg_last_cmd='file'
	  ;;

	# 
	fin | fini | finis | finish | r )

	  (( _Dbg_return_level=${#FUNCNAME[@]}-3 ))
	  _Dbg_last_cmd='finish'
	  return 0
	  ;;

	#  Set stack frame
	frame )
	  _Dbg_do_frame $args
	  _Dbg_last_cmd='frame'
	  ;;

	# print help command menu
	help )
	  _Dbg_do_help $args ;;

	#  Set signal handle parameters
	ha | han | hand | handl | handle )
	  _Dbg_do_handle $args
	  ;;

	#  Info subcommands
	i | in | inf | info )
	  _Dbg_do_info $args
	  ;;

	# List line.
	# print lines in file
	list )
	  _Dbg_do_list $args
	  _Dbg_last_cmd='list'
	  ;;

	# Load (read in) lines of a file
	lo | loa | load )
	  _Dbg_do_load $args
	  ;;

	# kill program
	k | ki | kil | kill )
	  _Dbg_do_kill $args
	  ;;

	# next/single-step N times (default 1)
	next | sk | ski | skip )
	  _Dbg_last_next_step_cmd="$_Dbg_cmd"
	  _Dbg_last_next_step_args=$args
	  _Dbg_do_next_skip $_Dbg_cmd $args
	  if [[ $_Dbg_cmd == sk* ]] ; then
	    _Dbg_inside_skip=1
	    _Dbg_last_cmd='skip'
	  else
	    _Dbg_last_cmd='next'
	  fi
	  return $_Dbg_inside_skip
	  ;;

	# print globbed or substituted variables
	print )
	  _Dbg_do_print "$args"
	  _Dbg_last_cmd='print'
	  ;;

	# print working directory
	pwd )
	  _Dbg_do_pwd
	  ;;

	# exit the debugger and debugged program
	quit )
	  _Dbg_last_cmd='quit'
	  _Dbg_do_quit $args
	  ;;

	# restart debug session.
	restart )
	  _Dbg_last_cmd='restart'
	  _Dbg_do_restart $args
	  ;;

	# return from function/source without finishing executions
	return )
	  _Dbg_step_ignore=1
	  _Dbg_write_journal "_Dbg_step_ignore=$_Dbg_step_ignore"
	  IFS="$_Dbg_old_IFS";
	  _Dbg_last_cmd='return'
	  return 2
	  ;;

	# Search backwards for pattern
	rev | reve | rever | revers | reverse )
	  _Dbg_do_search_back $args
	  _Dbg_last_cmd='reverse'
	  ;;

	# Search forwards for pattern
	sea | sear | searc | search | \
        for | forw | forwa | forwar | forward )
	  _Dbg_do_search $args
	  _Dbg_last_cmd='search'
	  ;;

	# Command to set debugger options
	set )
	  _Dbg_do_set $args
	  _Dbg_last_cmd='set'
	  ;;

	# Command to show debugger settings
	show )
	  _Dbg_do_show $args
	  _Dbg_last_cmd='show'
	  ;;

	# run shell command. Has to come before ! below.
	shell | '!!' )
	  eval $args ;;

	# Send signal to process
	si | sig | sign | signa | signal )
	  _Dbg_do_signal $args
	  _Dbg_last_cmd='signal'
	  ;;

	# Run a debugger comamnd file
	so | sou | sour | sourc | source )
	  _Dbg_do_source $args
	  ;;

	# single-step 
	step | 'step+' | 'step-' )
	  _Dbg_do_step "$_Dbg_cmd" $args
	  return 0
	  ;;

	# toggle execution trace
	t | to | tog | togg | toggl | toggle )
	  _Dbg_do_trace
	  ;;

	# Set a one-time breakpoint
	tb | tbr | tbre | tbrea | tbreak )
	  _Dbg_do_break 1 $args 
	  _Dbg_last_cmd='tbreak'
	  ;;

	# Trace a function
	tr | tra | tra | trac | trace )
	  _Dbg_do_trace_fn $args 
	  ;;

	# Set the output tty
	tty )
	  _Dbg_do_tty $args 
	  _Dbg_prompt_output=${_Dbg_tty:-/dev/null}
	  ;;

	# Move call stack up
	up )
	  _Dbg_do_up $args
	  _Dbg_last_cmd='up'
	  ;;

	# Add a debugger command alias
	unalias )
	  _Dbg_do_unalias $args 
	  _Dbg_last_cmd="unalias"
         ;;

	# Undisplay display-number
	und | undi | undis | undisp | undispl | undispla | undisplay )
	  _Dbg_do_undisplay $args
	  ;;

	# Remove a function trace
	unt | untr | untra | untrac | untrace )
	  _Dbg_do_untrace_fn $args 
	  ;;

	# Show version information
	ve | ver | vers | versi | versio | version | M )
	  _Dbg_do_show_versions
	  ;;

	# List window around line.
	w | wi | win | wind | windo | window )
	  ((_startline=_curline - _Dbg_listsize/2))
	  (( $_startline <= 0 )) && _startline=1
	  _Dbg_list $_Dbg_frame_last_filename $_startline
	  ;;

	# watch variable
	wa | wat | watch | W )
	  local -a a
	  a=($args)
	  local first=${a[0]}
	  if [[ $first == '' ]] ; then
	    _Dbg_do_watch 0
	  elif ! _Dbg_defined "$first" ; then
	      _Dbg_msg "Can't set watch: no such variable $first."
	  else
	      unset a first
	      _Dbg_do_watch 0 "\$$args"
	  fi
	  ;;

	# Watch expression
	watche | We )
	  _Dbg_do_watch 1 "$args"
	  ;;

	# Frame Stack listing
	where )
	  _Dbg_do_backtrace 2 $args
	  ;;

	# List all breakpoints and actions.
	L )
	  _Dbg_do_list_brkpt
	  _Dbg_list_watch
	  _Dbg_list_action
	  ;;

	# Remove all actions
	A )
	  _Dbg_do_clear_all_actions $args
	  ;;

	# List debugger command history
	H )
	  _Dbg_history_remove_item
	  _Dbg_do_history_list $args
	  ;;

	#  S List subroutine names
	S )
	  _Dbg_do_list_functions $args
	  ;;

	# Dump variables
	V )
	  _Dbg_do_list_variables "$args"
	  ;;

	# Has to come after !! of "shell" listed above
        # Run an item from the command history
	\!* | history )
	  _Dbg_do_history $args
	  ;;

	'' )
	  # Redo last_cmd
	  if [[ -n $_Dbg_last_cmd ]] ; then 
	      _Dbg_cmd=$_Dbg_last_cmd 
	      _Dbg_redo=1
	  fi
	  ;;
	* ) 

	   if (( _Dbg_autoeval )) ; then
	     _Dbg_do_eval $_Dbg_cmd $args
	   else
             _Dbg_undefined_cmd "$_Dbg_cmd"
	     _Dbg_history_remove_item
	     # local -a last_history=(`history 1`)
	     # history -d ${last_history[0]}
	   fi
	  ;;
      esac
      done # while (( $_Dbg_redo ))

      IFS=$_Dbg_space_IFS;
      eval "_Dbg_prompt=$_Dbg_prompt_str"
      return 10
}

_Dbg_preloop() {
  if (($_Dbg_annotate)) ; then
      _Dbg_annotation 'breakpoints' _Dbg_do_info breakpoints
      # _Dbg_annotation 'locals'      _Dbg_do_backtrace 3 
      _Dbg_annotation 'stack'       _Dbg_do_backtrace 3 
  fi
}

_Dbg_postcmd() {
  if (($_Dbg_annotate)) ; then
      case $_Dbg_last_cmd in
        break | tbreak | disable | enable | condition | clear | delete ) 
	  _Dbg_annotation 'breakpoints' _Dbg_do_info breakpoints
        ;;
	up | down | frame ) 
	  _Dbg_annotation 'stack' _Dbg_do_backtrace 3
	;;
      * )
      esac
  fi
}
