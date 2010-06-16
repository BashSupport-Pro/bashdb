# -*- shell-script -*-
# break.sh - Bourne Again Shell Debugger Break/Watch/Action routines
#
#   Copyright (C) 2002, 2003, 2006, 2007, 2008, 2009, 2010 Rocky Bernstein 
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
#   with Bashdb; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

#================ VARIABLE INITIALIZATIONS ====================#

typeset -a _Dbg_keep
_Dbg_keep=('keep' 'del')  

typeset -ar _Dbg_yn=("n" "y")         

# action data structures
typeset -ai _Dbg_action_line=()     # Line number of breakpoint
typeset -a  _Dbg_action_file=()     # filename of breakpoint
typeset -ai _Dbg_action_enable=()   # 1/0 if enabled or not
typeset -a  _Dbg_action_stmt=()     # Statement to eval when line is hit.
typeset -i  _Dbg_action_max=0       # Needed because we can't figure 
                                       # out what the max index is and arrays 
                                       # can be sparse

# Note: we loop over possibly sparse arrays with _Dbg_brkpt_max by adding one
# and testing for an entry. Could add yet another array to list only 
# used indices. Bash is kind of primitive.

# Line number of breakpoint $i
typeset -a _Dbg_brkpt_line; _Dbg_brkpt_line=()

# Number of breakpoints.
typeset -i _Dbg_brkpt_count=0

# filename of breakpoint $i
typeset -a  _Dbg_brkpt_file; _Dbg_brkpt_file=()

# 1/0 if enabled or not
typeset -a  _Dbg_brkpt_enable; _Dbg_brkpt_enable=()

# Number of times hit
typeset -a _Dbg_brkpt_counts; _Dbg_brkpt_counts=()

# Is this a onetime break?
typeset -a _Dbg_brkpt_onetime; _Dbg_brkpt_onetime=()

# Condition to eval true in order to stop.
typeset -a  _Dbg_brkpt_cond; _Dbg_brkpt_cond=()

# Needed because we can't figure out what the max index is and arrays
# can be sparse.
typeset -i  _Dbg_brkpt_max=0 

# Maps a resolved filename to a list of action line numbers in that file
typeset -A _Dbg_action_file2linenos; _Dbg_action_file2linenos=()

# Maps a resolved filename to a list of action entries.
typeset -A _Dbg_action_file2action; _Dbg_action_file2action=()

# Maps a resolved filename to a list of beakpoint line numbers in that file
typeset -A _Dbg_brkpt_file2linenos; _Dbg_brkpt_file2linenos=()

# Maps a resolved filename to a list of breakpoint entries.
typeset -A _Dbg_brkpt_file2brkpt; _Dbg_brkpt_file2brkpt=()

# Maps a resolved filename to a list of breakpoint entries.
typeset -A _Dbg_brkpt_file2brkpt; _Dbg_brkpt_file2brkpt=()
 
# Note: we loop over possibly sparse arrays with _Dbg_brkpt_max by adding one
# and testing for an entry. Could add yet another array to list only 
# used indices. Bash is kind of primitive.

# Watchpoint data structures
typeset -a  _Dbg_watch_exp=() # Watchpoint expressions
typeset -a  _Dbg_watch_val=() # values of watchpoint expressions
typeset -ai _Dbg_watch_arith=()  # 1 if arithmetic expression or not.
typeset -ai _Dbg_watch_count=()  # Number of times hit
typeset -ai _Dbg_watch_enable=() # 1/0 if enabled or not
typeset -i  _Dbg_watch_max=0     # Needed because we can't figure out what
                                    # the max index is and arrays can be sparse

typeset -r  _watch_pat="${int_pat}[wW]"

# Display data structures
typeset -a  _Dbg_disp_exp=() # Watchpoint expressions
typeset -ai _Dbg_disp_enable=() # 1/0 if enabled or not
typeset -i  _Dbg_disp_max=0     # Needed because we can't figure out what
                                    # the max index is and arrays can be sparse


#========================= FUNCTIONS   ============================#

_Dbg_save_breakpoints() {
  typeset file
  typeset -p _Dbg_brkpt_line         >> $_Dbg_statefile
  typeset -p _Dbg_brkpt_file         >> $_Dbg_statefile 
  typeset -p _Dbg_brkpt_cond         >> $_Dbg_statefile 
  typeset -p _Dbg_brkpt_count        >> $_Dbg_statefile 
  typeset -p _Dbg_brkpt_enable       >> $_Dbg_statefile
  typeset -p _Dbg_brkpt_onetime      >> $_Dbg_statefile
  typeset -p _Dbg_brkpt_max          >> $_Dbg_statefile
  typeset -p _Dbg_brkpt_file2linenos >> $_Dbg_statefile
  typeset -p _Dbg_brkpt_file2brkpt   >> $_Dbg_statefile

}

_Dbg_save_actions() {
  typeset -p _Dbg_action_line >> $_Dbg_statefile
  typeset -p _Dbg_action_file >> $_Dbg_statefile
  typeset -p _Dbg_action_enable >> $_Dbg_statefile
  typeset -p _Dbg_action_stmt >> $_Dbg_statefile
  typeset -p _Dbg_action_max >> $_Dbg_statefile
}

_Dbg_save_watchpoints() {
  typeset -p _Dbg_watch_exp >> $_Dbg_statefile
  typeset -p _Dbg_watch_val >> $_Dbg_statefile
  typeset -p _Dbg_watch_arith >> $_Dbg_statefile
  typeset -p _Dbg_watch_count >> $_Dbg_statefile
  typeset -p _Dbg_watch_enable >> $_Dbg_statefile
  typeset -p _Dbg_watch_max >> $_Dbg_statefile
}

_Dbg_save_display() {
  typeset -p _Dbg_disp_exp >> $_Dbg_statefile
  typeset -p _Dbg_disp_enable >> $_Dbg_statefile
  typeset -p _Dbg_disp_max >> $_Dbg_statefile
}

# Start out with general break/watchpoint functions first...

# Enable/disable breakpoint or watchpoint by entry numbers.
_Dbg_enable_disable() {
  if (($# == 0)) ; then
    _Dbg_errmsg 'Expecting a list of breakpoint/watchpoint numbers. Got none.'
    return 1
  fi
  typeset -i on=$1
  typeset en_dis=$2
  shift; shift

  if [[ $1 == 'display' ]] ; then
    shift
    typeset to_go="$@"
    typeset i
    eval "$_seteglob"
    for i in $to_go ; do 
      case $i in
	$int_pat )
	  _Dbg_enable_disable_display $on $en_dis $i
	;;
	* )
	  _Dbg_errmsg "Invalid entry number skipped: $i"
      esac
    done
    eval "$_resteglob"
    return 0
  elif [[ $1 == 'action' ]] ; then
    shift
    typeset to_go="$@"
    typeset i
    eval "$_seteglob"
    for i in $to_go ; do 
      case $i in
	$int_pat )
	  _Dbg_enable_disable_action $on $en_dis $i
	;;
	* )
	  _Dbg_errmsg "Invalid entry number skipped: $i"
      esac
    done
    eval "$_resteglob"
    return 0
  fi

  typeset to_go="$@"
  typeset i
  eval "$_seteglob"
  for i in $to_go ; do 
    case $i in
      $_watch_pat )
        _Dbg_enable_disable_watch $on $en_dis ${del:0:${#del}-1}
        ;;
      $int_pat )
        _Dbg_enable_disable_brkpt $on $en_dis $i
	;;
      * )
      _Dbg_errmsg "Invalid entry number skipped: $i"
    esac
  done
  eval "$_resteglob"
  return 0
}

# Print a message regarding how many times we've encounterd
# breakpoint number $1 if the number of times is greater than 0.
# Uses global array _Dbg_brkpt_counts.
function _Dbg_print_brkpt_count {
  typeset -i i; i=$1
  if (( _Dbg_brkpt_counts[i] != 0 )) ; then
    if (( _Dbg_brkpt_counts[i] == 1 )) ; then 
      _Dbg_printf "\tbreakpoint already hit 1 time" 
    else
      _Dbg_printf "\tbreakpoint already hit %d times" ${_Dbg_brkpt_counts[$i]}
    fi
  fi
}

#======================== BREAKPOINTS  ============================#

# clear all brkpts
_Dbg_clear_all_brkpt() {
  _Dbg_write_journal_eval "_Dbg_brkpt_file2linenos=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_file2brkpt=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_line=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_cond=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_file=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_enable=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_counts=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_onetime=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_count=0"
}

# Internal routine to a set breakpoint unconditonally. 

_Dbg_set_brkpt() {
    (( $# < 3 || $# > 4 )) && return 1
    typeset source_file
    source_file=$(_Dbg_expand_filename "$1")
    typeset -ir lineno=$2
    typeset -ir is_temp=$3
    typeset -r  condition=${4:-1}
    
    # Increment brkpt_max here because we are 1-origin
    ((_Dbg_brkpt_max++))
    ((_Dbg_brkpt_count++))
    
    
    _Dbg_brkpt_line[$_Dbg_brkpt_max]=$lineno
    _Dbg_brkpt_file[$_Dbg_brkpt_max]="$source_file"
    _Dbg_brkpt_cond[$_Dbg_brkpt_max]="$condition"
    _Dbg_brkpt_onetime[$_Dbg_brkpt_max]=$is_temp
    _Dbg_brkpt_counts[$_Dbg_brkpt_max]=0
    _Dbg_brkpt_enable[$_Dbg_brkpt_max]=1
    
    typeset dq_source_file
    dq_source_file=$(_Dbg_esc_dq "$source_file")
    typeset dq_condition=$(_Dbg_esc_dq "$condition")
    _Dbg_write_journal "_Dbg_brkpt_line[$_Dbg_brkpt_max]=$lineno"
    _Dbg_write_journal "_Dbg_brkpt_file[$_Dbg_brkpt_max]=\"$dq_source_file\""
    _Dbg_write_journal "_Dbg_brkpt_cond[$_Dbg_brkpt_max]=\"$dq_condition\""
    _Dbg_write_journal "_Dbg_brkpt_onetime[$_Dbg_brkpt_max]=$is_temp"
    _Dbg_write_journal "_Dbg_brkpt_counts[$_Dbg_brkpt_max]=\"0\""
    _Dbg_write_journal "_Dbg_brkpt_enable[$_Dbg_brkpt_max]=1"
    
    # Add line number with a leading and trailing space. Delimiting the
    # number with space helps do a string search for the line number.
    _Dbg_brkpt_file2linenos[$source_file]+=" $lineno "
    _Dbg_brkpt_file2brkpt[$source_file]+=" $_Dbg_brkpt_max "
    
    source_file=$(_Dbg_adjust_filename "$source_file")
    if (( $is_temp == 0 )) ; then 
	_Dbg_msg "Breakpoint $_Dbg_brkpt_max set in file ${source_file}, line $lineno."
    else 
	_Dbg_msg "One-time breakpoint $_Dbg_brkpt_max set in file ${source_file}, line $lineno."
    fi
    _Dbg_write_journal "_Dbg_brkpt_max=$_Dbg_brkpt_max"
    return 0
}

# Internal routine to unset the actual breakpoint arrays
# 0 is returned if successful
_Dbg_unset_brkpt_arrays() {
    (( $# != 1 )) && return 1
    typeset -i del=$1
    _Dbg_write_journal_eval "unset _Dbg_brkpt_line[$del]"
    _Dbg_write_journal_eval "unset _Dbg_brkpt_counts[$del]"
    _Dbg_write_journal_eval "unset _Dbg_brkpt_file[$del]"
    _Dbg_write_journal_eval "unset _Dbg_brkpt_enable[$del]"
    _Dbg_write_journal_eval "unset _Dbg_brkpt_cond[$del]"
    _Dbg_write_journal_eval "unset _Dbg_brkpt_onetime[$del]"
    ((_Dbg_brkpt_count--))
    return 0
}

# Internal routine to delete a breakpoint by file/line.
function _Dbg_unset_brkpt {
    (( $# != 2 )) && return 0
    typeset -r  filename=$1
    typeset -i lineno=$2
    typeset    fullname
    fullname=$(_Dbg_expand_filename "$filename")
  
    # FIXME: combine with _Dbg_hook_breakpoint_hit
    typeset -a linenos
    eval "linenos=(${_Dbg_brkpt_file2linenos[$fullname]})"
    typeset -a brkpt_nos
    eval "brkpt_nos=(${_Dbg_brkpt_file2brkpt[$fullname]})"

    typeset -i i
    for ((i=0; i < ${#linenos[@]}; i++)); do 
	if (( linenos[i] == lineno )) ; then
	    # Got a match, find breakpoint entry number
	    typeset -i brkpt_num
	    (( brkpt_num = brkpt_nos[i] ))
	    _Dbg_unset_brkpt_arrays $brkpt_num
	    unset linenos[i]
	    _Dbg_brkpt_file2linenos[$fullname]=${linenos[@]}
	    return 1
	fi
    done
    _Dbg_msg "No breakpoint found at $filename:$lineno"
    return $found
}

# Routine to a delete breakpoint by entry number: $1.
# Returns whether or not anything was deleted.
function _Dbg_delete_brkpt_entry() {
    (( $# == 0 )) && return 0
    typeset -r  del="$1"
    typeset -i  i
    typeset -i  found=0
    
    if [[ -z ${_Dbg_brkpt_file[$del]} ]] ; then
	_Dbg_errmsg "No breakpoint number $del."
	return 0
    fi
    typeset    source_file=${_Dbg_brkpt_file[$del]}
    typeset -i lineno=${_Dbg_brkpt_line[$del]}
    typeset -i try 
    typeset -a new_lineno_val; new_lineno_val=()
    typeset -a new_brkpt_nos; new_brkpt_nos=()
    typeset -i i=-1
    typeset -a brkpt_nos
    brkpt_nos=(${_Dbg_brkpt_file2brkpt[$source_file]})
    for try in ${_Dbg_brkpt_file2linenos[$source_file]} ; do 
	((i++))
	if (( brkpt_nos[i] == del )) ; then
	    if (( try != $lineno )) ; then
		_Dbg_errmsg 'internal brkpt structure inconsistency'
		return 0
	    fi
	    _Dbg_unset_brkpt_arrays $del
	    ((found++))
	else
	    new_lineno_val+=$try
	    new_brkpt_nos+=${brkpt_nos[$i]}
	fi
    done
    if (( found > 0 )) ; then
	if (( ${#new_lineno_val[@]} == 0 )) ; then 
	    _Dbg_write_journal_eval "unset '_Dbg_brkpt_file2linenos[$source_file]'"
	    _Dbg_write_journal_eval "unset '_Dbg_brkpt_file2brkpt[$source_file]'"
	else
	    _Dbg_write_journal_eval "_Dbg_brkpt_file2linenos[$source_file]=${new_lineno_val}"
	    _Dbg_write_journal_eval "_Dbg_brkpt_file2brkpt[$source_file]=${new_brkpt_nos}"
	fi
    fi
    
    return $found
}

# Enable/disable breakpoint(s) by entry numbers.
function _Dbg_enable_disable_brkpt() {
    (($# != 3)) && return 1
    typeset -i on=$1
    typeset en_dis=$2
    typeset -i i=$3
    if [[ -n "${_Dbg_brkpt_file[$i]}" ]] ; then
	if [[ ${_Dbg_brkpt_enable[$i]} == $on ]] ; then
	    _Dbg_errmsg "Breakpoint entry $i already ${en_dis}, so nothing done."
	    return 1
	else
	    _Dbg_write_journal_eval "_Dbg_brkpt_enable[$i]=$on"
	    _Dbg_msg "Breakpoint entry $i $en_dis."
	    return 0
	fi
    else
	_Dbg_errmsg "Breakpoint entry $i doesn't exist, so nothing done."
	return 1
    fi
}

#======================== WATCHPOINTS  ============================#

_Dbg_get_watch_exp_eval() {
  typeset -i i=$1
  typeset new_val

  if [[ $(eval echo \"${_Dbg_watch_exp[$i]}\") == "" ]]; then
    new_val=''
  elif (( ${_Dbg_watch_arith[$i]} == 1 )) ; then
    . ${_Dbg_libdir}/dbg-set-d-vars.inc
    eval let new_val=\"${_Dbg_watch_exp[$i]}\"
  else
    . ${_Dbg_libdir}/dbg-set-d-vars.inc
    eval new_val="${_Dbg_watch_exp[$i]}"
  fi
  echo $new_val
}

# Enable/disable watchpoint(s) by entry numbers.
_Dbg_enable_disable_watch() {
  typeset -i on=$1
  typeset en_dis=$2
  typeset -i i=$3
  if [ -n "${_Dbg_watch_exp[$i]}" ] ; then
    if [[ ${_Dbg_watch_enable[$i]} == $on ]] ; then
      _Dbg_msg "Watchpoint entry $i already $en_dis so nothing done."
    else
      _Dbg_write_journal_eval "_Dbg_watch_enable[$i]=$on"
      _Dbg_msg "Watchpoint entry $i $en_dis."
    fi
  else
    _Dbg_msg "Watchpoint entry $i doesn't exist so nothing done."
  fi
}

_Dbg_list_watch() {
  if [ ${#_Dbg_watch_exp[@]} != 0 ]; then
    typeset i=0 j
    _Dbg_msg "Num Type       Enb  Expression"
    for (( i=0; (( i < _Dbg_watch_max )); i++ )) ; do
      if [ -n "${_Dbg_watch_exp[$i]}" ] ;then
	_Dbg_printf '%-3d watchpoint %-4s %s' $i \
	  ${_Dbg_yn[${_Dbg_watch_enable[$i]}]} \
          "${_Dbg_watch_exp[$i]}"
	_Dbg_print_brkpt_count ${_Dbg_watch_count[$i]}
      fi
    done
  else
    _Dbg_msg "No watch expressions have been set."
  fi
}

_Dbg_delete_watch_entry() {
  typeset -i del=$1

  if [ -n "${_Dbg_watch_exp[$del]}" ] ; then
    _Dbg_write_journal_eval "unset _Dbg_watch_exp[$del]"
    _Dbg_write_journal_eval "unset _Dbg_watch_val[$del]"
    _Dbg_write_journal_eval "unset _Dbg_watch_enable[$del]"
    _Dbg_write_journal_eval "unset _Dbg_watch_count[$del]"
  else
    _Dbg_msg "Watchpoint entry $del doesn't exist so nothing done."
  fi
}

_Dbg_clear_watch() {
  if (( $# < 1 )) ; then
    typeset _Dbg_prompt_output=${_Dbg_tty:-/dev/null}
    read $_Dbg_edit -p "Delete all watchpoints? (y/n): " \
      <&$_Dbg_input_desc 2>>$_Dbg_prompt_output

    if [[ $REPLY = [Yy]* ]] ; then 
      _Dbg_write_journal_eval unset _Dbg_watch_exp[@]
      _Dbg_write_journal_eval unset _Dbg_watch_val[@]
      _Dbg_write_journal_eval unset _Dbg_watch_enable[@]
      _Dbg_write_journal_eval unset _Dbg_watch_count[@]
      _Dbg_msg "All Watchpoints have been cleared"
    fi
    return 0
  fi
  
  eval "$_seteglob"
  if [[ $1 == $int_pat ]]; then
    _Dbg_write_journal_eval "unset _Dbg_watch_exp[$1]"
    _msg "Watchpoint $i has been cleared"
  else
    _Dbg_list_watch
    _basdhb_msg "Please specify a numeric watchpoint number"
  fi
  
  eval "$_resteglob"
}   

#======================== ACTIONs  ============================#

# Add actions(s) at given line number of the current file.  $1 is
# the line number or _curline if omitted.  $2 is a condition to test
# for whether to stop.

_Dbg_do_action() {
  
  typeset n=${1:-$_curline}
  shift

  typeset stmt;
  if [ -z "$1" ] ; then
    condition=1
  else 
    condition="$*"
  fi

  typeset filename
  typeset -i line_number
  typeset full_filename

  _Dbg_linespec_setup $n

  if [[ -n $full_filename ]] ; then 
    if (( $line_number ==  0 )) ; then 
      _Dbg_msg "There is no line 0 to set action at."
    else 
      _Dbg_check_line $line_number "$full_filename"
      (( $? == 0 )) && \
	_Dbg_set_action "$full_filename" "$line_number" "$condition" 
    fi
  else
    _Dbg_file_not_read_in $filename
  fi
}

# clear all actions
_Dbg_do_clear_all_actions() {

  typeset _Dbg_prompt_output=${_Dbg_tty:-/dev/null}
  read $_Dbg_edit -p "Delete all actions? (y/n): " \
    <&$_Dbg_input_desc 2>>$_Dbg_prompt_output

  if [[ $REPLY != [Yy]* ]] ; then 
    return 1
  fi
  typeset -i k
  for (( k=0; (( k < ${#_Dbg_filenames[@]} )) ; k++ )) ; do
    typeset filename=${_filename[$k]}
    typeset filevar="`_Dbg_file2var $filename`"
    typeset action_a="_Dbg_action_${filevar}"
    unset ${action_a}[$k]
  done
  _Dbg_write_journal_eval "_Dbg_action_line=()"
  _Dbg_write_journal_eval "_Dbg_action_stmt=()"
  _Dbg_write_journal_eval "_Dbg_action_file=()"
  _Dbg_write_journal_eval "_Dbg_action_enable=()"
  return 0
}

# delete actions(s) at given file:line numbers. If no file is given
# use the current file.
_Dbg_do_clear_action() {
  typeset -r n=${1:-$_curline}

  typeset filename
  typeset -i line_number
  typeset full_filename

  _Dbg_linespec_setup $n

  if [[ -n $full_filename ]] ; then 
    if (( $line_number ==  0 )) ; then 
      _Dbg_msg "There is no line 0 to clear action at."
    else 
      _Dbg_check_line $line_number "$full_filename"
      (( $? == 0 )) && \
	_Dbg_unset_action "$full_filename" "$line_number"
      typeset -r found=$?
      if [[ $found != 0 ]] ; then 
	_Dbg_msg "Removed $found action(s)."
      else 
	_Dbg_msg "Didn't find any actions to remove at $n."
      fi
    fi
  else
    _Dbg_file_not_read_in $filename
  fi
}

# list actions
_Dbg_list_action() {

  if [ ${#_Dbg_action_line[@]} != 0 ]; then
    _Dbg_msg "Actions at following places:"
    typeset -i i

    _Dbg_msg "Num Enb Stmt               file:line"
    for (( i=0; (( i < _Dbg_action_max )) ; i++ )) ; do
      if [[ -n ${_Dbg_action_line[$i]} ]] ; then
	typeset source_file=${_Dbg_action_file[$i]}
	source_file=$(_Dbg_adjust_filename "$source_file")
	_Dbg_printf "%-3d %3d %-18s %s:%s" $i ${_Dbg_action_enable[$i]} \
	  "${_Dbg_action_stmt[$i]}" \
	  $source_file ${_Dbg_action_line[$i]}
      fi
    done
  else
    _Dbg_msg "No actions have been set."
  fi
}

# Internal routine to a set breakpoint unconditonally. 

_Dbg_set_action() {
    typeset source_file
    source_file=$(_Dbg_expand_filename "$1")

    typeset -ir lineno=$2
    typeset -r stmt=${3:-1}

    _Dbg_action_line[$_Dbg_action_max]=$lineno
    _Dbg_action_file[$_Dbg_action_max]="$source_file"
    _Dbg_action_stmt[$_Dbg_action_max]="$stmt"
    _Dbg_action_enable[$_Dbg_action_max]=1
    
    typeset dq_source_file=$(_Dbg_esc_dq "$source_file")
    typeset dq_stmt=$(_Dbg_esc_dq "stmt")

    _Dbg_write_journal "_Dbg_action_line[$_Dbg_action_max]=$lineno"
    _Dbg_write_journal "_Dbg_action_file[$_Dbg_action_max]=\"$dq_source_file\""
    _Dbg_write_journal "_Dbg_action_stmt[$_Dbg_action_max]=\"$dq_stmt\""
    _Dbg_write_journal "_Dbg_action_enable[$_Dbg_action_max]=1"

    # Add line number with a leading and trailing space. Delimiting the
    # number with space helps do a string search for the line number.
    _Dbg_action_file2linenos[$source_file]+=" $lineno "
    _Dbg_brkpt_file2action[$source_file]+=" $_Dbg_action_max "

    source_file=$(_Dbg_adjust_filename "$source_file")
    _Dbg_msg "Breakpoint $_Dbg_action_max set at ${source_file}:$lineno."
    ((_Dbg_action_max++))
    _Dbg_write_journal "_Dbg_action_max=$_Dbg_action_max"
    return 0
}

# Internal routine to delete a breakpoint by file/line.
_Dbg_unset_action() {
  typeset -r  filename=$1
  typeset -ir line=$2
  typeset -r filevar="`_Dbg_file2var $filename`"
  typeset -i found=0
  
  typeset -r entries=`_Dbg_get_assoc_array_entry "_Dbg_action_$filevar" $line`
  typeset -i del
  for del in $entries ; do 
    if [[ -z ${_Dbg_action_file[$del]} ]] ; then
      _Dbg_msg "No action found at $filename:$line"
      continue
    fi
    if [[ ${_Dbg_action_file[$del]} != $filename ]] ; then 
      _Dbg_msg "action inconsistency:" \
	"$filename[$line] lists ${_Dbg_action_file[$del]} at entry $del"
    else
      _Dbg_write_journal_eval "unset _Dbg_action_line[$del]"
      _Dbg_write_journal_eval "unset _Dbg_action_stmt[$del]"
      _Dbg_write_journal_eval "unset _Dbg_action_file[$del]"
      _Dbg_write_journal_eval "unset _Dbg_action_enable[$del]"
      ((found++))
    fi
  done
  _Dbg_write_journal_eval unset _Dbg_action_$filevar[$line]
  return $found
}

# Routine to a delete breakpoint/watchpoint by entry numbers.
_Dbg_do_action_delete() {
  typeset -r  to_go=$@
  typeset -i  i
  typeset -i  found=0
  
  eval "$_seteglob"
  for del in $to_go ; do 
    case $del in
      $int_pat )
	_Dbg_delete_action_entry $del
        ((found += $?))
	;;
      * )
	_Dbg_msg "Invalid entry number skipped: $del"
    esac
  done
  eval "$_resteglob"
  [[ $found != 0 ]] && _Dbg_msg "Removed $found action(s)."
  return $found
}

#======================== DISPLAYs  ============================#

# Enable/disable display by entry numbers.
_Dbg_disp_enable_disable() {
  if [ -z "$1" ] ; then 
    _Dbg_msg "Expecting a list of display numbers. Got none."
    return 1
  fi
  typeset -i on=$1
  typeset en_dis=$2
  shift; shift

  typeset to_go="$@"
  typeset i
  eval "$_seteglob"
  for i in $to_go ; do 
    case $i in
      $int_pat )
        _Dbg_enable_disable_display $on $en_dis $i
	;;
      * )
      _Dbg_msg "Invalid entry number skipped: $i"
    esac
  done
  eval "$_resteglob"
  return 0
}

_Dbg_eval_all_display() {
  typeset -i i
  for (( i=0; i < _Dbg_disp_max ; i++ )) ; do
    if [ -n "${_Dbg_disp_exp[$i]}" ] \
      && [[ ${_Dbg_disp_enable[i]} != 0 ]] ; then
      _Dbg_printf_nocr "%2d (%s): " $i "${_Dbg_disp_exp[i]}"
      _Dbg_do_eval "${_Dbg_disp_exp[i]}"
    fi
  done
}  

# Enable/disable display(s) by entry numbers.
_Dbg_enable_disable_display() {
  typeset -i on=$1
  typeset en_dis=$2
  typeset -i i=$3
  if [ -n "${_Dbg_disp_exp[$i]}" ] ; then
    if [[ ${_Dbg_disp_enable[$i]} == $on ]] ; then
      _Dbg_errmsg "Display entry $i already ${en_dis}, so nothing done."
    else
      _Dbg_write_journal_eval "_Dbg_disp_enable[$i]=$on"
      _Dbg_msg "Display entry $i $en_dis."
    fi
  else
    _Dbg_errmsg "Display entry $i doesn't exist, so nothing done."
  fi
}
