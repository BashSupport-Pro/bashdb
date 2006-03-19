# dbg-cmds.inc - Bourne Again Shell Debugger Top-level debugger commands
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006 Rocky Bernstein rocky@cpan.org
#
#   Bash is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   Bash is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with Bash; see the file COPYING.  If not, write to the Free Software
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
typeset -ir _Dbg_MAX_INPUT_DESC=9
typeset -i  _Dbg_input_desc=_Dbg_INPUT_START_DESC-1 # will ++ before use

# Are we inside the middle of a "skip" command?
typeset -i  _Dbg_inside_skip=0

# A variable holding a space is set so it can be used in a "set prompt" command
# ("read" in the main command loop will remove a trailing space so we need
# another way to allow a user to enter spaces in the prompt.)

typeset _Dbg_space=' '

# Should we allow editing of debugger commands? 
# The value should either be '-e' or ''
typeset _Dbg_edit='-e'

# What do we use for a debugger prompt? Technically we don't need to
# use the above $bashdb_space in the assignment below, but we put it
# in to suggest to a user that this is how one gets a spaces into the
# prompt.

typeset _Dbg_prompt_str='bashdb${_Dbg_less}${#_Dbg_history[@]}${_Dbg_greater}$_Dbg_space'

# The arguments in the last "print" command.
typeset _Dbg_last_print_args=''

# The arguments in the last "x" command.
typeset _Dbg_last_x_args=''

# ===================== FUNCTIONS =======================================

# Note: We have to be careful here in naming "local" variables. In contrast
# to other places in the debugger, because of the read/eval loop, they are
# in fact seen by those using the debugger. So in contrast to other "local"s
# in the debugger, we prefer to preface these with _Dbg_.
_Dbg_cmdloop() {

  # THIS SHOULD BE DONE IN dbg-sig.inc, but there's a bug in BASH in 
  # trying to change "trap RETURN" inside a "trap RETURN" handler....
  # Turn off return trapping. Not strictly necessary, since it *should* be 
  # covered by the _Dbg_ test below if we've named functions correctly.
  # However turning off the RETURN trap should reduce unnecessary calls.
  # trap RETURN  

  _Dbg_inside_skip=0

  # Evaluate all the display expressions
  _Dbg_eval_all_display

  # Loop over all pending open input file descriptors
  while (( $_Dbg_input_desc >= $_Dbg_INPUT_START_DESC )) ; do
    local _Dbg_cmd;
    local _Dbg_args;

    # Set up prompt to show shell level.
    local _Dbg_greater=''
    local _Dbg_less=''
    local -i _Dbg_i=0
    for (( _Dbg_i=0 ; _Dbg_i < BASHDB_LEVEL ; _Dbg_i++ )) ; do
      _Dbg_greater=">$_Dbg_greater"
      _Dbg_less="<$_Dbg_less"
    done

    for (( _Dbg_i=0 ; _Dbg_i < BASH_SUBSHELL ; _Dbg_i++ )) ; do
      _Dbg_greater=")$_Dbg_greater"
      _Dbg_less="$_Dbg_less("
    done

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
    while read $_Dbg_edit -p "$_Dbg_prompt" \
      _Dbg_cmd _Dbg_args \
      <&$_Dbg_input_desc 2>>$_Dbg_prompt_output; do

     # Set default next, step or skip command
     if [[ -z $_Dbg_cmd ]]; then
	_Dbg_cmd=$_Dbg_last_next_step_cmd
	_Dbg_args=$_Dbg_last_next_step_args
      fi

     local dq_cmd=$(_Dbg_esc_dq "$_Dbg_cmd")
     local dq_args=$(_Dbg_esc_dq "$_Dbg_args")
     # _Dbg_write_journal_eval doesn't work here. Don't really understand
     # how to get it to work. So we do this in two steps.
     _Dbg_write_journal \
        "_Dbg_history[${#_Dbg_history[@]}]=\"$dq_cmd $dq_args\""
     _Dbg_history[${#_Dbg_history[@]}]="$_Dbg_cmd $_Dbg_args"

     _Dbg_hi=${#_Dbg_history[@]}

      local -i _Dbg_redo=1
      while (( $_Dbg_redo )) ; do

	_Dbg_redo=0

      case $_Dbg_cmd in

	# Comment line
	[#]* ) 
	  _Dbg_remove_history_item
	  ;;

	# List window up to _curline
	- )
	  local -i start_line=(_curline+1-$_Dbg_listsize)
	  local -i count=($_Dbg_listsize)
	  if (( start_line <= 0 )) ; then
	    ((count=count+start_line-1))
	    start_line=1;
	  fi
	  _Dbg_list $_cur_source_file $start_line $count
	  ;;

	# list current line
	. )
	  _Dbg_list $_cur_source_file $_curline 1
	  ;;

	# Search forwards for pattern
	/* )
	  _Dbg_cmd_search $_Dbg_cmd
	  ;;

	# Search backwards for pattern
	[?]* )
	  _Dbg_cmd_search_back $_Dbg_cmd
	  ;;

	# Set action to be silently run when a line is hit
	a )
	  _Dbg_cmd_action $_Dbg_args ;;

	# Set breakpoint on a line
	b | br | bre | brea | break )
	  _Dbg_cmd_break 0 $_Dbg_args ;;

	# Continue
	c | cont | conti |contin |continu | continue )
	  _Dbg_cmd_continue $_Dbg_args
	  if [[ $? == 0 ]] ; then
	    IFS="$_Dbg_old_IFS";
	    _Dbg_write_journal_eval \
	      "_Dbg_old_set_opts=\"$_Dbg_old_set_opts -o functrace\""
	    return 0
	  fi
	  ;;

	# Change Directory
	cd )
	  cd $_Dbg_args
	  _Dbg_cmd_pwd
	  ;;

	# complete
	com | comp | compl | comple |complet | complete )
	  _Dbg_cmd_complete $_Dbg_args
	  ;;

	# Breakpoint/Watchpoint Conditions
	cond | condi |condit |conditi | conditio | condition )
	  _Dbg_cmd_condition $_Dbg_args
	  ;;

	# Delete all breakpoints by line number.
	# Note we use "d" as an alias for "clear" to be compatible
	# with the Perl5 debugger.
	d | cl | cle | clea | clea | clear )
	  _Dbg_cmd_clear_brkpt $_Dbg_args
	  ;;

	# Delete breakpoints by entry numbers. Note "d" is an alias for
	# clear.
	de | del | dele | delet | delete )
	  _Dbg_cmd_delete $_Dbg_args
	  ;;

	# Set up a script for debugging into.
	deb | debu | debug )
	  _Dbg_cmd_debug $_Dbg_args
	  # Skip over the execute statement which presumably we ran above.
	  _Dbg_cmd_next_step_skip "skip" 1
	  IFS="$_Dbg_old_IFS";
	  return 1
	  ;;

	# Disable breakpoints
	di | dis | disa | disab | disabl | disable )
	  _Dbg_cmd_disable $_Dbg_args
	  ;;

	# Display expression
	disp | displ | displa| display )
	  _Dbg_cmd_display $_Dbg_args
	  ;;

	# Delete all breakpoints.
	D | deletea | deleteal | deleteall )
	  _Dbg_clear_all_brkpt
	  ;;

	# List stack 1 up
	do | dow | down )
	  _Dbg_cmd_down $_Dbg_args
	  ;;

	# evaluate as bash command
	e | ev | eva | eval )
	  _Dbg_cmd_eval $_Dbg_args
	  ;;

	# evaluate as bash command
	en | ena | enab | enabl | enable )
	  _Dbg_cmd_enable $_Dbg_args
	  ;;

	# 
	fil | file )
	  _Dbg_cmd_file $_Dbg_args
	  ;;

	# 
	fin | fini | finis | finish | r )

	  (( _Dbg_return_level=${#FUNCNAME[@]}-2 ))
	  return 0
	  ;;

	#  View source in file
	fr | fra | fra | frame )
	  _Dbg_cmd_frame $_Dbg_args
	  ;;

	#  Set signal handle parameters
	ha | han | hand | handl | handle )
	  _Dbg_cmd_handle $_Dbg_args
	  ;;

	#  Info subcommands
	i | in | inf | info )
	  _Dbg_cmd_info $_Dbg_args
	  ;;

	# List line.
	# print lines in file
	l | li | lis | list )
	  _Dbg_cmd_list $_Dbg_args
	  ;;

	# next/single-step N times (default 1)
	n | ne | nex | next | s | st | ste | step | sk | ski | skip )
	  _Dbg_last_next_step_cmd="$_Dbg_cmd"
	  _Dbg_last_next_step_args=$_Dbg_args
	  _Dbg_cmd_next_step_skip $_Dbg_cmd $_Dbg_args
	  if [[ $_Dbg_cmd == sk* ]] ; then
	    _Dbg_inside_skip=1
	    return 1
	  else
	    return 0
	  fi
	  ;;

	# print globbed or substituted variables
	p | pr | pri | prin | print )
	  _Dbg_cmd_print "$_Dbg_args"
	  ;;

	# print working directory
	pw | pwd )
	  _Dbg_cmd_pwd
	  ;;

	# quit
	q | qu | qui | quit )
	  _Dbg_cmd_quit $_Dbg_args
	  ;;

	# Search backwards for pattern
	rev | reve | rever | revers | reverse )
	  _Dbg_cmd_search_back $_Dbg_args
	  ;;

	# return from function/source without finishing executions
	ret | retu | retur | return )
	  _Dbg_steps=1
	  _Dbg_write_journal "_Dbg_steps=$_Dbg_steps"
	  IFS="$_Dbg_old_IFS";
	  return 2
	  ;;

	# Run a debugger set command
	se | set )
	  _Dbg_cmd_set $_Dbg_args
	  ;;

	# Search forwards for pattern
	sea | sear | searc | search | \
        for | forw | forwa | forwar | forward )
	  _Dbg_cmd_search $_Dbg_args
	  ;;

	# Run a debugger show command
	sh | sho | show )
	  _Dbg_cmd_show $_Dbg_args
	  ;;

	# Run a debugger comamnd file
	so | sou | sour | sourc | source )
	  _Dbg_cmd_source $_Dbg_args
	  ;;

	# toggle execution trace
	t | to | tog | togg | toggl | toggle )
	  _Dbg_cmd_trace
	  ;;

	# Set breakpoint on a line
	tb | tbr | tbre | tbrea | tbreak )
	  _Dbg_cmd_break 1 $_Dbg_args ;;

	# Set the output tty
	tt | tty )
	  _Dbg_cmd_tty $_Dbg_args 
	  _Dbg_prompt_output=${_Dbg_tty:-/dev/null}
	  ;;

	# List call stack up
	u | up )
	  _Dbg_cmd_up $_Dbg_args
	  ;;

	# List call stack up
	un | undi | undis | undisp | undispl | undispla | undisplay )
	  _Dbg_cmd_undisplay $_Dbg_args
	  ;;

	# List window around line.
	w | wi | win | wind | windo | window )
	  ((_startline=_curline - _Dbg_listsize/2))
	  (( $_startline <= 0 )) && _startline=1
	  _Dbg_list $_cur_source_file $_startline
	  ;;

	# intelligent print of variable, function or expression
	x | examine )
	  _Dbg_cmd_x "$_Dbg_args"
	  ;;

	# List all breakpoints and actions.
	L )
	  _Dbg_cmd_list_brkpt
	  _Dbg_list_watch
	  _Dbg_list_action
	  ;;

	# print help command menu
	'?' | h | he | hel | help )
	  _Dbg_cmd_help $_Dbg_args ;;

	# run shell command. Has to come before ! below.
	'!!' | sh | she | shell )
	  eval $_Dbg_args ;;

	\!* | hi | his | hist | histo | histor | history )
	  _Dbg_remove_history_item
	  _Dbg_cmd_history_parse $_Dbg_args
	  if (( $history_num >= 0 )) ; then 
	    if (( $history_num < ${#_Dbg_history[@]} )) ; then 
	      set ${_Dbg_history[$history_num]}
	      _Dbg_cmd=$1
	      shift
	      _Dbg_args="$@"
	      _Dbg_redo=1;
	    else
	      _Dbg_msg \
	      "Number $history_num should be less than ${#_Dbg_history[@]}"
	    fi
	  fi
	  ;;

	# Remove all actions
	A )
	  _Dbg_cmd_clear_all_actions $_Dbg_args
	  ;;

	# Run debugger command history
	H )
	  _Dbg_remove_history_item
	  _Dbg_cmd_history_list $_Dbg_args
	  ;;

	# restart debug session.
	R | re | res | rest | resta | restar | restart | ru | run )
	  _Dbg_cmd_restart $_Dbg_args
	  ;;

	#  S List subroutine names
	S )
	  _Dbg_cmd_list_subroutines $_Dbg_args
	  ;;

	# Stack trace
	T | wh | whe | wher | where | bt| back | backtrace )
	  _Dbg_cmd_stack_trace 1 $_Dbg_args;
	  ;;

	# Dump variables
	V )
	  _Dbg_cmd_list_variables "$_Dbg_args"
	  ;;

	# Watch expression
	We | watche )
	  _Dbg_cmd_watch 1 "$_Dbg_args"
	  ;;

	# watch variable
	W | wa | wat | watch )
	  local -a a
	  a=($_Dbg_args)
	  local first=${a[0]}
	  if [[ $first == '' ]] ; then
	    _Dbg_cmd_watch 0
	  else
	    if [[ 0 == `_Dbg_is_var $first` ]] ; then
	      _Dbg_msg "Can't set watch: no such variable $first."
	    else
	      unset a first
	      _Dbg_cmd_watch 0 "\$$_Dbg_args"
	    fi
	  fi
	  ;;

	# Show version information
	M | ve | ver | vers | versi | versio | version )
	  _Dbg_cmd_show_versions
	  ;;

	* ) 
          _Dbg_msg "Undefined command: \"$_Dbg_cmd\". Try \"help\"." 
	  _Dbg_remove_history_item
	  ;;
      esac
      done

      IFS=$_Dbg_space_IFS;
      eval "_Dbg_prompt=$_Dbg_prompt_str"
    done

    ((_Dbg_input_desc--))
  done

  # EOF hit. Same as quit without arguments
  _Dbg_msg "" # Cause <cr> since EOF may not have put in.
  _Dbg_cmd_quit
}

# Set up to Debug into another script...
# TODO: would work better if instead of using $source_line below
# which might have several statements, we could just pick up the next
# single statement.
_Dbg_cmd_debug() {

  # set -xv
  local script_cmd=${@:-$_Dbg_bash_command}

  # We need to expand variables that might be in $script_cmd.
  # set_Dbg_nested_debug_cmd is set up to to be eval'd below.
  local set_Dbg_debug_cmd="local _Dbg_debug_cmd=\"$script_cmd\"";

  [ -z "$BASH" ] && BASH='bash'

  eval "$_seteglob"
  # Add appropriate bash debugging options
  if [[ $_Dbg_script != 1 ]] ; then
    # Running "bash --debugger", so prepend "bash --debugger"
    set_Dbg_debug_cmd="local _Dbg_debug_cmd=\"$BASH --debugger $script_cmd\"";
  elif [[ $0/// == *bashdb/// ]] ; then
    # Running "bashdb", so prepend "bash bashdb .."
    set_Dbg_debug_cmd="local _Dbg_debug_cmd=\"$BASH $0 -q -L $_Dbg_libdir $script_cmd\"";
  fi
  eval "$_resteglob"
  eval $set_Dbg_debug_cmd

  if (( _Dbg_basename_only )) ; then 
    _Dbg_msg "Debugging new script with $script_cmd"
  else
    _Dbg_msg "Debugging new script with $_Dbg_debug_cmd"
  fi
  local -r old_quit_on_quit=$BASHDB_QUIT_ON_QUIT
  export BASHDB_QUIT_ON_QUIT=1
  export BASHDB_BASENAME_ONLY="$_Dbg_basename_only"
  ((BASHDB_LEVEL++))
  $_Dbg_debug_cmd
  ((BASHDB_LEVEL--))
  export BASHDB_QUIT_ON_QUIT=$old_quit_on_quit
}

# V [![pat]] List variables and values for whose variables names which 
# match pat $1. If ! is used, list variables that *don't* match. 
# If pat ($1) is omitted, use * (everything) for the pattern.
_Dbg_cmd_list_variables() {
  local _Dbg_old_glob="$GLOBIGNORE"
  GLOBIGNORE="*"
  
  local _Dbg_match="$1"
  _Dbg_match_inverted=no
  case ${_Dbg_match} in
    \!*)
      _Dbg_match_inverted=yes
      _Dbg_match=${_Dbg_match#\!}
    ;;
    "")
      _Dbg_match='*'
    ;;
  esac
  local _Dbg_list=`declare -p`
  local _Dbg_old_ifs=${IFS}
  IFS="
"
  local _Dbg_temp=${_Dbg_list}
  _Dbg_list=""
  local -i i=0
  local -a _Dbg_list

  # GLOBIGNORE protects us against using the result of
  # a glob expansion, but it doesn't protect us from
  # actually performing it, and this can bring bash down
  # with a huge _Dbg_source_ variable being globbed.
  # So here we disable globbing momentarily
  set -o noglob
  for _Dbg_item in ${_Dbg_temp}; do
    _Dbg_list[${i}]="${_Dbg_item}"
    i=${i}+1
  done
  set +o noglob
  IFS=${_Dbg_old_ifs}
  local _Dbg_item=""
  local _Dbg_skip=0
  local _Dbg_show_cmd=""
   _Dbg_show_cmd=`echo -e "case \\${_Dbg_item} in \n${_Dbg_match})\n echo yes;;\n*)\necho no;; esac"`
  
  for (( i=0; (( i < ${#_Dbg_list[@]} )) ; i++ )) ; do
    _Dbg_item=${_Dbg_list[$i]}
    case ${_Dbg_item} in
      *\ \(\)\ )
        _Dbg_skip=1
      ;;
      \})
        _Dbg_skip=0
        continue
    esac
    if [[ _Dbg_skip -eq 1 ]]; then
      continue
    fi

    # Ignore all _Dbg_ variables here because the following
    # substitutions takes a long while when it encounters
    # a big _Dbg_source_
    case ${_Dbg_item} in
      _Dbg_*)  # Hide/ignore debugger variables.
        continue;	
      ;;
    esac
    
    _Dbg_item=${_Dbg_item/=/==/}
    _Dbg_item=${_Dbg_item%%=[^=]*}
    case ${_Dbg_item} in
      _=);;
      *=)
        _Dbg_item=${_Dbg_item%=}
        local _Dbg_show=`eval $_Dbg_show_cmd`
        if [[ "$_Dbg_show" != "$_Dbg_match_inverted" ]]; then
            if [[ -n ${_Dbg_item} ]]; then
              local _Dbg_var=`declare -p ${_Dbg_item} 2>/dev/null`
	      if [[ -n "$_Dbg_var" ]]; then
		# Uncomment the following 3 lines to use literal
		# linefeeds
#		_Dbg_var=${_Dbg_var//\\\\n/\\n}
#                _Dbg_var=${_Dbg_var//
#/\n}
		# Comment the following 3 lines to use literal linefeeds
                _Dbg_var=${_Dbg_var//\\\\n/\\\\\\n}
                _Dbg_var=${_Dbg_var//
/\\n}
                _Dbg_var=${_Dbg_var#* * }
                _Dbg_msg ${_Dbg_var}
	      fi
            fi
        fi
      ;;
      *)
      ;;
    esac

  done
  GLOBIGNORE=$_Dbg_old_glob
}

_Dbg_cmd_eval() {

  echo ". ${_Dbg_libdir}/dbg-set-d-vars.inc" > $_Dbg_evalfile
  echo "$@" >> $_Dbg_evalfile
  if [[ -n $_basdhb_tty  ]] ; then
    . $_Dbg_evalfile >>$_Dbg_tty
  else
    . $_Dbg_evalfile
  fi
}

_Dbg_cmd_file() {

  local filename
  if [[ -z "$1" ]] ; then
    _Dbg_msg "Need to give a filename for the file command"
    return
  fi
  _Dbg_glob_filename $1
  if [[ ! -f "$filename" ]] && [[ ! -x "$filename" ]] ; then
    _Dbg_msg "Source file $filename does not exist as a readable regular file."
    return
  fi
  local filevar=`_Dbg_file2var ${BASH_SOURCE[3]}`
  _Dbg_set_assoc_scalar_entry "_Dbg_file_cmd_" $filevar "$filename"
  local source_file="${BASH_SOURCE[3]}"
  (( _Dbg_basename_only )) && source_file=${source_file##*/}
  _Dbg_msg "File $filename will be used when $source_file is referenced."
}

_Dbg_cmd_next_step_skip() {

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
    let _Dbg_steps=${count:-1}
  else
    _Dbg_msg "Argument ($count) should be a number or nothing."
    _Dbg_steps=1
  fi
  _Dbg_write_journal "_Dbg_steps=$_Dbg_steps"
}

_Dbg_cmd_print() {
  local -r _Dbg_expr=${@:-"$_Dbg_last_print_args"}
  local -r dq_expr=$(_Dbg_esc_dq "$_Dbg_expr")
  . ${_Dbg_libdir}/dbg-set-d-vars.inc
  eval "_Dbg_msg $_Dbg_expr"
  _Dbg_last_print_args="$dq_expr"
}

_Dbg_cmd_pwd() {
  local _Dbg_cwd=$(pwd)
  (( _Dbg_basename_only )) && _Dbg_cwd=${_Dbg_cwd##*/}
  _Dbg_msg "Working directory ${_Dbg_cwd}."
}

# Restart script in same way with saved arguments (probably the same
# ones as we were given before).
_Dbg_cmd_restart() {

  _Dbg_cleanup;

  local script_args
  if (( $# != 0 )) ; then 
    script_args="$@"
  else
    script_args="${_Dbg_script_args[@]}"
  fi

  local exec_cmd="$0 $script_args";
  if [[ $_Dbg_script != 1 ]] ; then
    [ -z "$BASH" ] && BASH='bash'
    if [ $_cur_source_file == $_Dbg_bogus_file ] ; then
      script_args="--debugger -c \"$BASH_EXECUTION_STRING\""
      exec_cmd="$BASH --debugger -c \"$BASH_EXECUTION_STRING\"";
    else
      exec_cmd="$BASH --debugger $0 $script_args";
    fi
  elif [[ -n "$BASH" ]] ; then
      local exec_cmd="$BASH $0 $script_args";
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
    _Dbg_cmd_quit 0
  fi
  _Dbg_save_state
  cd $_Dbg_init_cwd
  exec $exec_cmd
}

# Handle command-file source. If the filename's okay we just increase the
# input-file descriptor by one and redirect input which will
# be picked up in next debugger command loop.
_Dbg_cmd_source() {
  local filename
  if [[ -z "$1" ]] ; then
    _Dbg_msg "Need to give a filename for the source command"
    return
  fi
  _Dbg_glob_filename $1
  if [ "$filename" != '/dev/stdin' ] && [[ ! -f $filename ]] ; then
    _Dbg_msg "Source file $filename does not exist as a regular file."
    return
  fi
  if [[ -r $filename ]] || [[ "$filename" == '/dev/stdin' ]] ; then
    if ((_Dbg_input_desc < _Dbg_MAX_INPUT_DESC )) ; then 
      ((_Dbg_input_desc++))
      _Dbg_input[$_Dbg_input_desc]=$filename
      local _Dbg_redirect_cmd="exec $_Dbg_input_desc<$filename"
      eval $_Dbg_redirect_cmd
    else 
      local -i max_nesting
      ((max_nesting=_Dbg_MAX_INPUT_DESC-_Dbg_INPUT_START_DESC+1))
      _Dbg_msg "Source nesting too deep; nesting can't be greater than $max_nesting."
    fi
  else
    _Dbg_msg "Source file $filename is not readable."
  fi
}

# toggle execution trace feature
_Dbg_cmd_trace() {
  ((_Dbg_linetrace=!$_Dbg_linetrace))

  _Dbg_msg "Line trace = \c"
  let " $_Dbg_linetrace" && _Dbg_msg "on" || _Dbg_msg "off"
}

# Set output tty
_Dbg_cmd_tty() {
  if [[ -z "$1" ]] ; then
    _Dbg_msg "Argument required (terminal name for running target process)."
    return 1
  fi
  if ! $(touch $1 >/dev/null 2>/dev/null); then 
    _Dbg_msg "Can't access $1 for writing."
    return 1
  fi
  if [[ ! -w $1 ]] ; then
    _Dbg_msg "tty $1 needs to be writable"
    return 1
  fi
  _Dbg_tty=$1
  return 0
}

_Dbg_cmd_x() {
  local -r _Dbg_expr=${@:-"$_Dbg_last_x_args"}
  local _Dbg_result
  if (( `_Dbg_is_var $_Dbg_expr` )) ; then
    _Dbg_result=`declare -p $_Dbg_expr`
    _Dbg_msg "$_Dbg_result"
  elif (( `_Dbg_is_function $_Dbg_expr` )) ; then 
    _Dbg_result=`declare -f $_Dbg_expr`
    _Dbg_msg "$_Dbg_result"
  else 
    local -i _Dbg_rc
    eval let _Dbg_result=$_Dbg_expr 2>/dev/null; _Dbg_rc=$?
    if (( $_Dbg_rc != 0 )) ; then
      _Dbg_cmd_print "$_Dbg_expr"
    else
      _Dbg_msg "$_Dbg_result"
    fi
  fi
  _Dbg_last_x_args="$_Dbg_x_args"
}

_Dbg_save_state() {
  _Dbg_statefile=`_Dbg_tempname statefile`
  echo "" > $_Dbg_statefile
  _Dbg_save_breakpoints
  _Dbg_save_actions
  _Dbg_save_watchpoints
  _Dbg_save_display
  _Dbg_save_Dbg_set
  echo "unset BASHDB_RESTART_FILE" >> $_Dbg_statefile
  echo "rm $_Dbg_statefile" >> $_Dbg_statefile
  export BASHDB_RESTART_FILE="$_Dbg_statefile"
  _Dbg_write_journal "export BASHDB_RESTART_FILE=\"$_Dbg_statefile\""

}


_Dbg_save_Dbg_set() {
  declare -p _Dbg_basename_only  >> $_Dbg_statefile
  declare -p _Dbg_debug_debugger >> $_Dbg_statefile
  declare -p _Dbg_edit           >> $_Dbg_statefile
  declare -p _Dbg_listsize       >> $_Dbg_statefile
  declare -p _Dbg_prompt_str     >> $_Dbg_statefile
  declare -p _Dbg_show_command   >> $_Dbg_statefile
}

_Dbg_restore_state() {
  local statefile=$1
  . $1
}

# ================== INITIALIZATION =====================================

_Dbg_cmd_source '/dev/stdin'

# List of command files to process
typeset -a _Dbg_input

# Have we already specified  where to read debugger input from?
# Note: index 0 is only set by bashdb. It is not used otherwise for I/O
# like those indices >= _Dbg_INPUT_START_DESC are.
if [ -n "$BASHDB_INPUT" ] ; then 
  _Dbg_input=($BASHDB_INPUT)
  _Dbg_cmd_source ${_Dbg_input[0]}
  _Dbg_no_init=1
fi

if [[ -z $_Dbg_no_init && -r ~/.bashdbinit ]] ; then
  _Dbg_cmd_source ~/.bashdbinit
fi

# BASHDB_LEVEL is the number of times we are nested inside a debugger
# by virtue of running "debug" for example.
if [[ -z "${BASHDB_LEVEL}" ]] ; then
  export BASHDB_LEVEL=1
fi

# temp file for internal eval'd commands
typeset _Dbg_evalfile=`_Dbg_tempname eval`

# File to save information that needs to be passed from a subshell
# to a parent shell
typeset _Dbg_journal=`_Dbg_tempname journal`
if [ ! -f _Dbg_journal ] ; then 
  _Dbg_write_journal "BASHDB_QUIT_LEVELS=0"
fi

# This is put at the so we have something at the end to stop at 
# when we debug this. By stopping at the end all of the above functions
# and variables can be tested.
_Dbg_cmd_ver='$Id: dbg-cmds.inc,v 1.8 2006/03/19 21:48:47 rockyb Exp $'

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
