# dbg-brk.inc - Bourne Again Shell Debugger Break/Watch/Action routines

#   Copyright (C) 2002, 2003, 2006, 2007 Rocky Bernstein 
#   rockyb@users.sourceforge.net
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

#================ VARIABLE INITIALIZATIONS ====================#

declare -r _Dbg_brk_ver=\
'$Id: dbg-brk.inc,v 1.15 2007/03/02 07:56:34 rockyb Exp $'

typeset -ar _Dbg_yn=("n" "y")         
typeset -ar _Dbg_keep=('keep' 'del')  

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

# Breakpoint data structures
typeset -ai _Dbg_brkpt_line=()     # Line number of breakpoint
typeset -a  _Dbg_brkpt_file=()     # filename of breakpoint
typeset -a  _Dbg_brkpt_enable=()   # 1/0 if enabled or not
typeset -ai _Dbg_brkpt_count=()    # Number of times hit
typeset -ai _Dbg_brkpt_onetime=()  # Is this a onetime break?
typeset -a  _Dbg_brkpt_cond=()     # Condition to eval true in order to stop.
typeset -i  _Dbg_brkpt_max=0       # Needed because we can't figure out what
                               # the max index is and arrays can be sparse
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


# Error message for file not read in
_Dbg_file_not_read_in() {
    local -r filename=$(_Dbg_adjust_filename "$1")
    _Dbg_msg "File $filename not found in read-in files."
    _Dbg_msg "See 'info files' for a list of known files and"
    _Dbg_msg "'load' to read in a file."
}

# Common routine for setup of commands that take a single
# linespec argument. We assume the following variables 
# which we store into:
#  filename, line_number, full_filename

_Dbg_linespec_setup() {
  local linespec=${1:-''}
  if [[ -z $linespec ]] ; then
    _Dbg_msg "Invalid line specification, null given"
  fi
  local -a word=($(_Dbg_parse_linespec "$linespec"))
  if [[ ${#word[@]} == 0 ]] ; then
    _Dbg_msg "Invalid line specification: $linespec"
    return
  fi
  
  filename=${word[2]}
  local -ir is_function=${word[1]}
  line_number=${word[0]}
  full_filename=`_Dbg_is_file $filename`

  if (( is_function )) ; then
      if [[ -z $full_filename ]] ; then 
	  _Dbg_readin "$filename"
	  full_filename=`_Dbg_is_file $filename`
      fi
  fi
}

# Error message for file not read in
_Dbg_file_not_read_in() {
    local -r filename=$(_Dbg_adjust_filename ${1:-""})
    _Dbg_msg "File $filename not found in read-in files."
    _Dbg_msg "See 'info files' for a list of known files and"
    _Dbg_msg "'load' to read in a file."
}

_Dbg_save_breakpoints() {
  local file
  for file in ${_Dbg_filenames[@]} ; do  
    local filevar="`_Dbg_file2var $file`"
    declare -p _Dbg_brkpt_$filevar >> $_Dbg_statefile 2>/dev/null
  done        
  declare -p _Dbg_brkpt_line >> $_Dbg_statefile
  declare -p _Dbg_brkpt_file >> $_Dbg_statefile 
  declare -p _Dbg_brkpt_cond >> $_Dbg_statefile 
  declare -p _Dbg_brkpt_count >> $_Dbg_statefile 
  declare -p _Dbg_brkpt_enable >> $_Dbg_statefile
  declare -p _Dbg_brkpt_onetime >> $_Dbg_statefile
  declare -p _Dbg_brkpt_max >> $_Dbg_statefile

}

_Dbg_save_actions() {
  for file in ${_Dbg_filenames[@]} ; do  
    local filevar="`_Dbg_file2var $file`"
    declare -p _Dbg_action_$filevar >> $_Dbg_statefile 2>/dev/null
  done        
  declare -p _Dbg_action_line >> $_Dbg_statefile
  declare -p _Dbg_action_file >> $_Dbg_statefile
  declare -p _Dbg_action_enable >> $_Dbg_statefile
  declare -p _Dbg_action_stmt >> $_Dbg_statefile
  declare -p _Dbg_action_max >> $_Dbg_statefile
}

_Dbg_save_watchpoints() {
  declare -p _Dbg_watch_exp >> $_Dbg_statefile
  declare -p _Dbg_watch_val >> $_Dbg_statefile
  declare -p _Dbg_watch_arith >> $_Dbg_statefile
  declare -p _Dbg_watch_count >> $_Dbg_statefile
  declare -p _Dbg_watch_enable >> $_Dbg_statefile
  declare -p _Dbg_watch_max >> $_Dbg_statefile
}

_Dbg_save_display() {
  declare -p _Dbg_disp_exp >> $_Dbg_statefile
  declare -p _Dbg_disp_enable >> $_Dbg_statefile
  declare -p _Dbg_disp_max >> $_Dbg_statefile
}

# Start out with general break/watchpoint functions first...

# Routine to a delete breakpoint/watchpoint by entry numbers.
_Dbg_do_delete() {
  local -r  to_go=$@
  local -i  i
  local -i  found=0
  
  # set -xv
  eval "$_seteglob"
  for del in $to_go ; do 
    case $del in
      $_watch_pat )
        _Dbg_delete_watch_entry ${del:0:${#del}-1}
        ;;
      $int_pat )
	_Dbg_delete_brkpt_entry $del
        ((found += $?))
	;;
      * )
	_Dbg_msg "Invalid entry number skipped: $del"
    esac
  done
  eval "$_resteglob"
  [[ $found != 0 ]] && _Dbg_msg "Removed $found breakpoint(s)."
  return $found
  # set +xv
}

# Enable/disable breakpoint or watchpoint by entry numbers.
_Dbg_enable_disable() {
  if [ -z "$1" ] ; then 
    _Dbg_msg "Expecting a list of breakpoint/watchpoint numbers. Got none."
    return 1
  fi
  local -i on=$1
  local en_dis=$2
  shift; shift

  if [[ $1 = 'display' ]] ; then
    shift
    local to_go="$@"
    local i
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
  elif [[ $1 = 'action' ]] ; then
    shift
    local to_go="$@"
    local i
    eval "$_seteglob"
    for i in $to_go ; do 
      case $i in
	$int_pat )
	  _Dbg_enable_disable_action $on $en_dis $i
	;;
	* )
	  _Dbg_msg "Invalid entry number skipped: $i"
      esac
    done
    eval "$_resteglob"
    return 0
  fi

  local to_go="$@"
  local i
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
      _Dbg_msg "Invalid entry number skipped: $i"
    esac
  done
  eval "$_resteglob"
  return 0
}

_Dbg_do_continue() {
  # set -xv

  if (( ! _Dbg_running )) ; then
      _Dbg_msg "The program is not being run."
      return
  fi

  [[ -z "$1" ]] && return 0
  local filename
  local -i line_number
  local full_filename

  _Dbg_linespec_setup $1

  if [[ -n $full_filename ]] ; then 
    if (( $line_number ==  0 )) ; then 
      _Dbg_msg "There is no line 0 to continue at."
    else 
      _Dbg_check_line $line_number "$full_filename"
      (( $? == 0 )) && \
	_Dbg_set_brkpt "$full_filename" "$line_number" 1 1
      return 0
    fi
  else
    _Dbg_file_not_read_in $filename
  fi
  return 1
}

# Enable breakpoint(s)/watchpoint(s) by entry number(s).
_Dbg_do_enable() {
  _Dbg_enable_disable 1 "enabled" $@
}

# Disable breakpoint(s)/watchpoint(s) by entry number(s).
_Dbg_do_disable() {
  _Dbg_enable_disable 0 "disabled" $@
}

_Dbg_print_brkpt_count() {
  local -ir i=$1
  if (( _Dbg_brkpt_count[$i] != 0 )) ; then
    if (( _Dbg_brkpt_count[$i] == 1 )) ; then 
      _Dbg_printf "\tbreakpoint already hit 1 time" 
    else
      _Dbg_printf "\tbreakpoint already hit %d times" ${_Dbg_brkpt_count[$i]}
    fi
  fi
}

#======================== BREAKPOINTS  ============================#

# Add breakpoint(s) at given line number of the current file.  $1 is
# the line number or _curline if omitted.  $2 is a condition to test
# for whether to stop.

_Dbg_do_break() {

  local -i is_temp=$1
  shift

  local n=${1:-$_curline}
  shift

  local condition=${1:-''};
  if [[ "$n" == 'if' ]]; then
    n=$_curline
  elif [[ -z $condition ]] ; then
    condition=1
  elif [[ $condition == 'if' ]] ; then
    shift
  fi
  if [[ -z $condition ]] ; then
    condition=1
  else 
    condition="$*"
  fi

  local filename
  local -i line_number
  local full_filename

  _Dbg_linespec_setup $n

  if [[ -n $full_filename ]]  ; then 
    if (( $line_number ==  0 )) ; then 
      _Dbg_msg "There is no line 0 to break at."
    else 
      _Dbg_check_line $line_number "$full_filename"
      (( $? == 0 )) && \
	_Dbg_set_brkpt "$full_filename" "$line_number" $is_temp "$condition"
    fi
  else
    _Dbg_file_not_read_in $filename
  fi
}

# Set a condition for a given breakpoint $1 is a breakpoint number
# $2 is a condition. If not given, set "unconditional" or 1.
# returns 0 if success or 1 if fail.
_Dbg_do_condition() {
  # set -x
  local -r n=$1
  shift 
  local condition="$@"
  # set -xv

  if [[ -z $n ]]; then
    _Dbg_msg "Argument required (breakpoint number)."
    return 1
  fi

  eval "$_seteglob"
  if [[ $n != $int_pat ]]; then
    eval "$_resteglob"
    _Dbg_msg "Bad breakpoint number: $n"
    return 1
  fi
  eval "$_resteglob"

  if [[ -z ${_Dbg_brkpt_file[$n]} ]] ; then
    _Dbg_msg "Breakpoint entry $n is not set. Condition not changed."
    return 1
  fi
  
  if [[ -z $condition ]] ; then
    condition=1
    _Dbg_msg "Breakpoint $n now unconditional."
  fi
  _Dbg_brkpt_cond[$n]="$condition"
  return 0
}

# delete brkpt(s) at given file:line numbers. If no file is given
# use the current file.
_Dbg_do_clear_brkpt() {
  # set -x
  local -r n=${1:-$_curline}

  local filename
  local -i line_number
  local full_filename

  _Dbg_linespec_setup $n

  if [[ -n $full_filename ]] ; then 
    if (( $line_number ==  0 )) ; then 
      _Dbg_msg "There is no line 0 to clear."
    else 
      _Dbg_check_line $line_number "$full_filename"
      if (( $? == 0 )) ; then
	_Dbg_unset_brkpt "$full_filename" "$line_number"
	local -r found=$?
	if [[ $found != 0 ]] ; then 
	  _Dbg_msg "Removed $found breakpoint(s)."
	else 
	  _Dbg_msg "Didn't find any breakpoints to remove at $n."
	fi
      fi
    fi
  else
    _Dbg_file_not_read_in $filename
  fi
}

# list breakpoints and break condition.
# If $1 is given just list those associated for that line.
_Dbg_do_list_brkpt() {

  local brkpt_num=${1:-''}
  eval "$_seteglob"
  if [[ -n $brkpt_num ]] ; then 
    if [[ $brkpt_num != $int_pat ]]; then
      _Dbg_msg "Bad breakpoint number $brkpt_num."
    elif [[ -z ${_Dbg_brkpt_file[$brkpt_num]} ]] ; then
      _Dbg_msg "Breakpoint entry $brkpt_num is not set."
    else
      local -r -i i=$brkpt_num
      local source_file=${_Dbg_brkpt_file[$i]}
      source_file=$(_Dbg_adjust_filename "$source_file")
      _Dbg_msg "Num Type       Disp Enb What"
      _Dbg_printf "%-3d breakpoint %-4s %-3s %s:%s" $i \
	${_Dbg_keep[${_Dbg_brkpt_onetime[$i]}]} \
	${_Dbg_yn[${_Dbg_brkpt_enable[$i]}]} \
	$source_file ${_Dbg_brkpt_line[$i]}
      if [[ ${_Dbg_brkpt_cond[$i]} != '1' ]] ; then
	_Dbg_printf "\tstop only if %s" "${_Dbg_brkpt_cond[$i]}"
      fi
      _Dbg_print_brkpt_count ${_Dbg_brkpt_count[$i]}
    fi
    eval "$_resteglob"
    return
  fi

  if [ ${#_Dbg_brkpt_line[@]} != 0 ]; then
    local -i i

    _Dbg_msg "Num Type       Disp Enb What"
    for (( i=1; (( i <= _Dbg_brkpt_max )) ; i++ )) ; do
      local source_file=${_Dbg_brkpt_file[$i]}
      if [[ -n ${_Dbg_brkpt_line[$i]} ]] ; then
	source_file=$(_Dbg_adjust_filename "$source_file")
	_Dbg_printf "%-3d breakpoint %-4s %-3s %s:%s" $i \
	  ${_Dbg_keep[${_Dbg_brkpt_onetime[$i]}]} \
	  ${_Dbg_yn[${_Dbg_brkpt_enable[$i]}]} \
	  $source_file ${_Dbg_brkpt_line[$i]}
	if [[ ${_Dbg_brkpt_cond[$i]} != '1' ]] ; then
	  _Dbg_printf "\tstop only if %s" "${_Dbg_brkpt_cond[$i]}"
	fi
	if (( _Dbg_brkpt_count[$i] != 0 )) ; then
	  _Dbg_print_brkpt_count ${_Dbg_brkpt_count[$i]}
	fi
      fi
    done
  else
    _Dbg_msg "No breakpoints have been set."
  fi
}

# clear all brkpts
_Dbg_clear_all_brkpt() {

  local -i k
  for (( k=0; (( k < ${#_Dbg_filenames[@]} )) ; k++ )) ; do
    local filename=${_filename[$k]}
    local filevar="`_Dbg_file2var $filename`"
    local brkpt_a="_Dbg_brkpt_${filevar}"
    _Dbg_write_journal_eval "unset ${brkpt_a}[$k]"
  done
  _Dbg_write_journal_eval "_Dbg_brkpt_line=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_cond=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_file=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_enable=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_count=()"
  _Dbg_write_journal_eval "_Dbg_brkpt_onetime=()"
}

# Internal routine to a set breakpoint unconditonally. 

_Dbg_set_brkpt() {
  local source_file=$1
  local -ir line=$2
  local -ir is_temp=$3
  local -r  condition=${4:-1}

  local -r filevar="`_Dbg_file2var $source_file`"

  local val_str=`_Dbg_get_assoc_array_entry "_Dbg_brkpt_$filevar" $line`

  # Increment brkpt_max here because we are 1-origin
  ((_Dbg_brkpt_max++))

  if [ -z "$val_str" ] ; then 
    val_str=$_Dbg_brkpt_max
  else
    val_str="$val_str $_Dbg_brkpt_max"
  fi

  _Dbg_brkpt_line[$_Dbg_brkpt_max]=$line
  _Dbg_brkpt_file[$_Dbg_brkpt_max]="$source_file"
  _Dbg_brkpt_cond[$_Dbg_brkpt_max]="$condition"
  _Dbg_brkpt_onetime[$_Dbg_brkpt_max]=$is_temp
  _Dbg_brkpt_count[$_Dbg_brkpt_max]=0
  _Dbg_brkpt_enable[$_Dbg_brkpt_max]=1

  local dq_source_file=$(_Dbg_esc_dq "$source_file")
  local dq_condition=$(_Dbg_esc_dq "$condition")
  _Dbg_write_journal "_Dbg_brkpt_line[$_Dbg_brkpt_max]=$line"
  _Dbg_write_journal "_Dbg_brkpt_file[$_Dbg_brkpt_max]=\"$dq_source_file\""
  _Dbg_write_journal "_Dbg_brkpt_cond[$_Dbg_brkpt_max]=\"$dq_condition\""
  _Dbg_write_journal "_Dbg_brkpt_onetime[$_Dbg_brkpt_max]=$is_temp"
  _Dbg_write_journal "_Dbg_brkpt_count[$_Dbg_brkpt_max]=\"0\""
  _Dbg_write_journal "_Dbg_brkpt_enable[$_Dbg_brkpt_max]=1"

  _Dbg_set_assoc_array_entry "_Dbg_brkpt_$filevar" $line $val_str
  source_file=$(_Dbg_adjust_filename "$source_file")
  if (( $is_temp == 0 )) ; then 
    _Dbg_msg "Breakpoint $_Dbg_brkpt_max set in file ${source_file}, line $line."
  else 
    _Dbg_msg "One-time breakpoint $_Dbg_brkpt_max set in file ${source_file}, line $line."
  fi
  _Dbg_write_journal "_Dbg_brkpt_max=$_Dbg_brkpt_max"
}

# Internal routine to unset the actual breakpoint arrays
_Dbg_unset_brkpt_arrays() {
  local -i del=$1
  _Dbg_write_journal_eval "unset _Dbg_brkpt_line[$del]"
  _Dbg_write_journal_eval "unset _Dbg_brkpt_count[$del]"
  _Dbg_write_journal_eval "unset _Dbg_brkpt_file[$del]"
  _Dbg_write_journal_eval "unset _Dbg_brkpt_enable[$del]"
  _Dbg_write_journal_eval "unset _Dbg_brkpt_cond[$del]"
  _Dbg_write_journal_eval "unset _Dbg_brkpt_onetime[$del]"
}

# Internal routine to delete a breakpoint by file/line.
_Dbg_unset_brkpt() {
  local -r  filename=$1
  local -ir line=$2
  local -r filevar="`_Dbg_file2var $filename`"
  local -r fullname="`_Dbg_expand_filename $filename`"
  local -i found=0
  
  # set -xv
  local -r entries=`_Dbg_get_assoc_array_entry "_Dbg_brkpt_$filevar" $line`
  local -i del
  for del in $entries ; do 
    if [[ -z ${_Dbg_brkpt_file[$del]} ]] ; then
      _Dbg_msg "No breakpoint found at $filename:$line"
      continue
    fi
    local brkpt_fullname=$(_Dbg_expand_filename ${_Dbg_brkpt_file[$del]})
    if [[ $brkpt_fullname != $fullname ]] ; then 
      _Dbg_msg "Brkpt inconsistency:" \
	"$filename[$line] lists ${_Dbg_brkpt_file[$del]} at entry $del"
    else
      _Dbg_unset_brkpt_arrays $del
      ((found++))
    fi
  done
  _Dbg_write_journal_eval "unset _Dbg_brkpt_$filevar[$line]"
  return $found
  # set +xv
}

# Routine to a delete breakpoint by entry number: $1.
# Returns whether or not anything was deleted.
_Dbg_delete_brkpt_entry() {
  local -r  del=$1
  local -i  i
  local -i  found=0
  
  # set -xv
  if [[ -z ${_Dbg_brkpt_file[$del]} ]] ; then
    _Dbg_msg "Breakpoint entry $del is not set."
    return 0
  fi
  local filevar="`_Dbg_file2var ${_Dbg_brkpt_file[$del]}`"
  local line=${_Dbg_brkpt_line[$del]}
  local -r  entries=`_Dbg_get_assoc_array_entry "_Dbg_brkpt_$filevar" $line`
  local     try 
  local -a  new_val=()
  for try in $entries ; do 
    if (( $try == $del )) ; then
      _Dbg_unset_brkpt_arrays $del
      found=1
    else
      if [[ -n ${_Dbg_brkpt_file[$try]} ]] ; then
	new_val[${#new_val[@]}]=$try
      fi
    fi
  done
  if [[ ${#new_val[@]} == 0 ]] ; then 
   _Dbg_write_journal_eval "unset _Dbg_brkpt_$filevar[$line]"
  else
    _Dbg_set_assoc_array_entry "_Dbg_brkpt_$filevar" $line "${new_val[@]}"
  fi

  return $found
  # set +xv
}

# Enable/disable breakpoint(s) by entry numbers.
_Dbg_enable_disable_brkpt() {
  local -i on=$1
  local en_dis=$2
  local -i i=$3
  if [[ -n "${_Dbg_brkpt_file[$i]}" ]] ; then
    if [[ ${_Dbg_brkpt_enable[$i]} == $on ]] ; then
      _Dbg_msg "Breakpoint entry $i already $en_dis so nothing done."
    else
      _Dbg_write_journal_eval "_Dbg_brkpt_enable[$i]=$on"
      _Dbg_msg "Breakpoint entry $i $en_dis."
    fi
  else
    _Dbg_msg "Breakpoint entry $i doesn't exist so nothing done."
  fi
}

#======================== WATCHPOINTS  ============================#

_Dbg_get_watch_exp_eval() {
  local -i i=$1
  local new_val

  if [[ `eval echo \"${_Dbg_watch_exp[$i]}\"` == "" ]]; then
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
  local -i on=$1
  local en_dis=$2
  local -i i=$3
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
    local i=0 j
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
  local -i del=$1

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
    local _Dbg_prompt_output=${_Dbg_tty:-/dev/null}
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

# Set or list watch command
_Dbg_do_watch() {
  if [ -z "$2" ]; then
    _Dbg_clear_watch 
  else 
    local -i n=_Dbg_watch_max++
    _Dbg_watch_arith[$n]="$1"
    shift
    _Dbg_watch_exp[$n]="$1"
    _Dbg_watch_val[$n]=`_Dbg_get_watch_exp_eval $n`
    _Dbg_watch_enable[$n]=1
    _Dbg_watch_count[$n]=0
    _Dbg_printf '%2d: %s==%s arith: %d' $n \
      "(${_Dbg_watch_exp[$n]})" ${_Dbg_watch_val[$n]} \
    ${_Dbg_watch_arith[$n]}
  fi
}

#======================== ACTIONs  ============================#

# Add actions(s) at given line number of the current file.  $1 is
# the line number or _curline if omitted.  $2 is a condition to test
# for whether to stop.

_Dbg_do_action() {
  
  local n=${1:-$_curline}
  shift

  local stmt;
  if [ -z "$1" ] ; then
    condition=1
  else 
    condition="$*"
  fi

  local filename
  local -i line_number
  local full_filename

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

  local _Dbg_prompt_output=${_Dbg_tty:-/dev/null}
  read $_Dbg_edit -p "Delete all actions? (y/n): " \
    <&$_Dbg_input_desc 2>>$_Dbg_prompt_output

  if [[ $REPLY != [Yy]* ]] ; then 
    return 1
  fi
  local -i k
  for (( k=0; (( k < ${#_Dbg_filenames[@]} )) ; k++ )) ; do
    local filename=${_filename[$k]}
    local filevar="`_Dbg_file2var $filename`"
    local action_a="_Dbg_action_${filevar}"
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
  # set -x
  local -r n=${1:-$_curline}

  local filename
  local -i line_number
  local full_filename

  _Dbg_linespec_setup $n

  if [[ -n $full_filename ]] ; then 
    if (( $line_number ==  0 )) ; then 
      _Dbg_msg "There is no line 0 to clear action at."
    else 
      _Dbg_check_line $line_number "$full_filename"
      (( $? == 0 )) && \
	_Dbg_unset_action "$full_filename" "$line_number"
      local -r found=$?
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
    local -i i

    _Dbg_msg "Num Enb Stmt               file:line"
    for (( i=0; (( i < _Dbg_action_max )) ; i++ )) ; do
      if [[ -n ${_Dbg_action_line[$i]} ]] ; then
	local source_file=${_Dbg_action_file[$i]}
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
  local source_file=$1
  local -ir line=$2
  local -r stmt=${3:-1}
  local -r filevar="`_Dbg_file2var $source_file`"

  local val_str=`_Dbg_get_assoc_array_entry "_Dbg_action_$filevar" $line`
  if [ -z "$val_str" ] ; then 
    val_str=$_Dbg_action_max
  else
    val_str="$val_str $_Dbg_action_max"
  fi

  _Dbg_action_line[$_Dbg_action_max]=$line
  _Dbg_action_file[$_Dbg_action_max]="$source_file"
  _Dbg_action_stmt[$_Dbg_action_max]="$stmt"
  _Dbg_action_enable[$_Dbg_action_max]=1

  local dq_source_file=$(_Dbg_esc_dq "$source_file")
  local dq_stmt=$(_Dbg_esc_dq "stmt")

  _Dbg_write_journal "_Dbg_action_line[$_Dbg_action_max]=$line"
  _Dbg_write_journal "_Dbg_action_file[$_Dbg_action_max]=\"$dq_source_file\""
  _Dbg_write_journal "_Dbg_action_stmt[$_Dbg_action_max]=\"$dq_stmt\""
  _Dbg_write_journal "_Dbg_action_enable[$_Dbg_action_max]=1"

  _Dbg_set_assoc_array_entry "_Dbg_action_$filevar" $line $val_str
  source_file=$(_Dbg_adjust_filename "$source_file")
  _Dbg_msg "Breakpoint $_Dbg_action_max set at ${source_file}:$line."
  ((_Dbg_action_max++))
  _Dbg_write_journal "_Dbg_action_max=$_Dbg_action_max"
}

# Internal routine to delete a breakpoint by file/line.
_Dbg_unset_action() {
  local -r  filename=$1
  local -ir line=$2
  local -r filevar="`_Dbg_file2var $filename`"
  local -i found=0
  
  # set -xv
  local -r entries=`_Dbg_get_assoc_array_entry "_Dbg_action_$filevar" $line`
  local -i del
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
  # set +xv
}

# Routine to a delete breakpoint/watchpoint by entry numbers.
_Dbg_do_action_delete() {
  local -r  to_go=$@
  local -i  i
  local -i  found=0
  
  # set -xv
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
  # set +xv
}

#======================== DISPLAYs  ============================#

# Enable/disable display by entry numbers.
_Dbg_disp_enable_disable() {
  if [ -z "$1" ] ; then 
    _Dbg_msg "Expecting a list of display numbers. Got none."
    return 1
  fi
  local -i on=$1
  local en_dis=$2
  shift; shift

  local to_go="$@"
  local i
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
  local -i i
  for (( i=0; i < _Dbg_disp_max ; i++ )) ; do
    if [ -n "${_Dbg_disp_exp[$i]}" ] \
      && [[ ${_Dbg_disp_enable[i]} != 0 ]] ; then
      _Dbg_printf_nocr "%2d (%s): " $i "${_Dbg_disp_exp[i]}"
      _Dbg_do_eval "${_Dbg_disp_exp[i]}"
    fi
  done
}  

# Set display command or list all current display expressions
_Dbg_do_display() {
  if [[ -z "$@" ]]; then
    _Dbg_eval_all_display
  else 
    local -i n=_Dbg_disp_max++
    _Dbg_disp_exp[$n]="$@"
    _Dbg_disp_enable[$n]=1
    _Dbg_printf '%2d: %s' $n "${_Dbg_disp_exp[$n]}"
  fi
}

# List display command(s)
_Dbg_do_list_display() {
  if [ ${#_Dbg_disp_exp[@]} != 0 ]; then
    local i=0 j
    _Dbg_msg "Display expressions:"
    _Dbg_msg "Num Enb Expression          "
    for (( i=0; (( i < _Dbg_disp_max )); i++ )) ; do
      if [ -n "${_Dbg_disp_exp[$i]}" ] ;then
	_Dbg_printf '%-3d %3d %s' \
	  $i ${_Dbg_disp_enable[$i]} "${_Dbg_disp_exp[$i]}"
      fi
    done
  else
    _Dbg_msg "No display expressions have been set."
  fi
}

# Enable/disable display(s) by entry numbers.
_Dbg_enable_disable_display() {
  local -i on=$1
  local en_dis=$2
  local -i i=$3
  if [ -n "${_Dbg_disp_exp[$i]}" ] ; then
    if [[ ${_Dbg_disp_enable[$i]} == $on ]] ; then
      _Dbg_msg "Display entry $i already $en_dis so nothing done."
    else
      _Dbg_write_journal_eval "_Dbg_disp_enable[$i]=$on"
      _Dbg_msg "Display entry $i $en_dis."
    fi
  else
    _Dbg_msg "Display entry $i doesn't exist so nothing done."
  fi
}

_Dbg_do_undisplay() {
  local -i del=$1

  if [ -n "${_Dbg_disp_exp[$del]}" ] ; then
    _Dbg_write_journal_eval "unset _Dbg_disp_exp[$del]"
    _Dbg_write_journal_eval "unset _Dbg_disp_enable[$del]"
  else
    _Dbg_msg "Display entry $del doesn't exist so nothing done."
  fi
}


#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
