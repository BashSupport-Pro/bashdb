# dbg-fns.inc - Bourne Again Shell Debugger Utility Functions
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2007 Rocky Bernstein
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

# Come here via DEBUG trap after each statement in script.
# This determines if we need to stop and go into the debugger 
# command loop or not.

# Add escapes to a string $1 so that when it is read back via "$1"
# it is the same as $1.
_Dbg_esc_dq() {
  builtin echo $1 | sed -e 's/[`$\"]/\\\0/g' 
}

# Set $? to $1 if supplied or the saved entry value of $?. 
_Dbg_set_dol_q () {
  return ${1:-$_Dbg_debugged_exit_code}
}

# Split $2 using $1 as the split character.  We accomplish this by
# temporarily resetting the variable IFS (input field separator).
#
# Example:
# local -a a=($(_Dbg_split ":" "file:line"))
# a[0] will have file and a{1] will have line.

_Dbg_split (){
  local old_IFS=$IFS
  local new_ifs=${1:-' '}
  shift
  local -r text=$*
  local -a array
  IFS="$new_ifs"
  array=( $text )
  echo ${array[@]}
  IFS=$old_IFS
}

# Return value of eval($1$2). Until bash has associative arrays,
# this is how we simulate such a datatype. In Perl this would be returning
# the value of  $1{$2}.

_Dbg_get_assoc_scalar_entry() {
#   set -xv
    local prefix=$1
#   echo "${BASH_SOURCE[1]}:${BASH_LINENO[1]} ${FUNCNAME[1]}"
    local entry=${2:-''}
    local cmd="echo \$${prefix}${entry}"
    eval $cmd
#   set +xv
}

# Set eval($1$2)=$2. Until bash has associative arrays,
# this is how we simulate such a datatype. In Perl this would be
# $1{$2}=$3.

_Dbg_set_assoc_scalar_entry() {
#  set -xv
  local prefix=$1
  local entry=$2
  local value=$3
  local cmd="${prefix}${entry}=$value"
  eval $cmd

  local dq_value=$(_Dbg_esc_dq "$value")
  _Dbg_write_journal "${prefix}${entry}=\"$dq_value\""

#  set +xv
}

# Return value of eval($1[$2]). If $2 is omitted, use _curline.  Until
# bash has associative arrays which can contain array elements this is
# how we simulate such a datatype.

_Dbg_get_assoc_array_entry() {
  local prefix=$1
  local lineno=${2:-$_curline}

  [[ -z $prefix ]] && _Dbg_msg "Internal debug error (gae) bad prefix"
  local entry="$prefix[$lineno]"
  local cmd="echo \"\${$entry}\""
  eval $cmd
}

# Evaluate eval($1[$2]=$3). If $2 is omitted, use _curline.  Until
# bash has associative arrays cich can contain array elements this is
# how we simulate such a datatype.

_Dbg_set_assoc_array_entry() {
#  set -xv
  local prefix=$1
  local lineno=$2
  shift; shift
  local value=$*
  
  [[ -z "$prefix" ]] && _Dbg_msg "Internal debug error (sae1) bad prefix"
  [[ -z "$lineno" ]] && _Dbg_msg "Internal debug error (sae2) bad lineno"
  [[ -z "$value" ]] && _Dbg_msg "Internal debug error (sae3) bad value"

  local entry="$prefix[$lineno]"
  local cmd="$entry=\"$value\""
  eval $cmd

  local dq_value=$(_Dbg_esc_dq "$value")
  _Dbg_write_journal "$entry=\"$dq_value\""

#  set +xv
}

# _Dbg_is_var echoes 1 if $1 is a defined variable or 0 otherwise. 
_Dbg_is_var() {
  declare -p $1 >/dev/null 2>&1
  if [[ $? != 0 ]] ; then 
    echo 0
  else
    echo 1
  fi
}

# _Dbg_is_function echoes 1 if $1 is a defined function or 0 otherwise. 
# if $2 is nonzero, system functions, i.e. those whose name starts with
# an underscore (_), are included in the search.
_Dbg_is_function() {
    local needed_fn=$1
    if [[ -z $needed_fn ]] ; then 
	echo 0
	return;
    fi
    local -i include_system=$2
    local -a fns_a
    fns_a=(`declare -F`)
    local -i i

    # Iterate skipping over consecutive single tokens "declare" and "-F"
    for (( i=2; (( i < ${#fns_a[@]} )) ; i += 3 )) ; do
	local fn="${fns_a[$i]}"
	[[ $fn == _* ]] && (( ! $include_system )) && continue
	if [[ $needed_fn ==  $fn ]] ; then
	    echo 1
	    return
	fi
    done
    echo 0
}

# _get_function echoes a list of all of the functions.
# if $1 is nonzero, system functions, i.e. those whose name starts with
# an underscore (_), are included in the search.
# FIXME add parameter search pattern.
_Dbg_get_functions() {
    local -i include_system=${1:-0}
    local    pat=${2:-*}
    local -a fns_a
    fns_a=(`declare -F`)
    local -a ret_fns=()
    local -i i
    local -i invert=0;

    if [[ $pat == !* ]] ; then 
	# Remove leading !
	pat=$(echo $pat | cut -c2-)
	invert=1
    fi	

    # Iterate skipping over consecutive single tokens "declare" and "-F"
    for (( i=2; (( i < ${#fns_a[@]} )) ; i += 3 )) ; do
	local fn="${fns_a[$i]}"
	[[ $fn == _* ]] && (( ! $include_system )) && continue
	if [[ $fn == $pat ]] ; then 
	     [[ $invert == 0 ]] && ret_fns[${#ret_fns[@]}]=$fn
	else
	     [[ $invert != 0 ]] && ret_fns[${#ret_fns[@]}]=$fn
	fi

    done
    echo ${ret_fns[@]}
}

# Parse linespec in $1 which should be one of
#   int
#   file:line
#   function-num
# Return triple (line,  is-function?, filename,)
# We return the filename last since that can have embedded blanks.
_Dbg_parse_linespec() {
  local linespec=$1
  eval "$_seteglob"
  case "$linespec" in

    # line number only - use _cur_source_file for filename
    $int_pat )	
      echo "$linespec 0 $_cur_source_file"
      ;;
    
    # file:line
    [^:][^:]*[:]$int_pat )
      # Split the POSIX way
      local line_word=${linespec##*:}
      local file_word=${linespec%${line_word}}
      file_word=${file_word%?}
      echo "$line_word 0 $file_word"
      ;;

    # Function name or error
    * )
      if [[ 1 == `_Dbg_is_function $linespec $_Dbg_debug_debugger` ]]; then 
	local -a word
	word=(`declare -F $linespec`)
	echo "${word[1]} 1 ${word[2]}"
      else
	echo ""
      fi
      ;;
   esac
}

# usage _Dbg_set_ftrace [-u] funcname [funcname...]
# Sets or unsets a function for stopping by setting 
# the -t or +t property to the function declaration.
#
_Dbg_set_ftrace() {
  local opt=-t tmsg="enabled" func 
  if [[ $1 == -u ]]; then
	opt=+t
	tmsg="disabled"
	shift
  fi
  for func; do
	  declare -f $opt $func
	  # _Dbg_msg "Tracing $tmsg for function $func"
  done
}

# Does things to after on entry of after an eval to set some debugger
# internal settings  
_Dbg_set_debugger_internal() {
  IFS="$_Dbg_space_IFS";
  PS4='+ dbg (${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]}\n'
}

_Dbg_restore_user_vars() {
  IFS="$_Dbg_space_IFS";
  set -$_Dbg_old_set_opts
  IFS="$_Dbg_old_IFS";
  PS4="$_Dbg_old_PS4"
}

# Do things for debugger entry. Set some global debugger variables
# Remove trapping ourselves. 
# We assume that we are nested two calls deep from the point of debug
# or signal fault. If this isn't the constant 2, then consider adding
# a parameter to this routine.

_Dbg_set_debugger_entry() {

  # Nuke DEBUG trap
  trap '' DEBUG

  _cur_fn=${FUNCNAME[2]}
  let _curline=${BASH_LINENO[1]}
  ((_curline < 1)) && let _curline=1

  _Dbg_old_IFS="$IFS"
  _Dbg_old_PS4="$PS4"
  _cur_source_file=${BASH_SOURCE[2]:-$_Dbg_bogus_file}
  _Dbg_stack_pos=$_Dbg_STACK_TOP
  _Dbg_listline=_curline
  _Dbg_set_debugger_internal
  _cur_source_file="`_Dbg_resolve_expand_filename $_cur_source_file`"
  _cur_filevar="`_Dbg_file2var $_cur_source_file`"
}

_Dbg_set_to_return_from_debugger() {
  _Dbg_rc=$?

  _Dbg_currentbp=0
  _Dbg_stop_reason=''
  if (( $1 != 0 )) ; then
    _Dbg_last_bash_command="$_Dbg_bash_command"
    _Dbg_last_curline="$_curline"
    _Dbg_last_source_file="$_cur_source_file"
  else
    _Dbg_last_curline==${BASH_LINENO[1]}
    _Dbg_last_source_file=${BASH_SOURCE[2]:-$_Dbg_bogus_file}
    _Dbg_last_bash_command="**unsaved _bashdb command**"
  fi

  trap '_Dbg_debug_trap_handler 0 "$BASH_COMMAND" "$@"' DEBUG

  _Dbg_restore_user_vars
}

# This is put at the so we have something at the end when we debug this.
typeset -r _Dbg_fns_ver=\
'$Id: dbg-fns.inc,v 1.10 2007/10/14 08:50:34 rockyb Exp $'

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; End: ***
