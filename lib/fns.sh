# -*- shell-script -*-
# fns.sh - Bourne Again Shell Debugger Utility Functions
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2007, 2008, 2009 Rocky Bernstein
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

# Return $2 copies of $1. If successful, $? is 0 and the return value
# is in result.  Otherwise $? is 1 and result ''
function _Dbg_copies { 
    result=''
    (( $# < 2 )) && return 1
    typeset -r string=$1
    typeset -i count=$2 || return 2;
    (( count > 0 )) || return 3
    builtin printf -v result "%${count}s" ' ' || return 3
    result=${result// /$string}
    return 0
}

# _Dbg_defined returns 0 if $1 is a defined variable or 1 otherwise. 
_Dbg_defined() {
  typeset -p $1 &>/dev/null
  if [[ $? != 0 ]] ; then 
    return 1
  else
    return 0
  fi
}

# Add escapes to a string $1 so that when it is read back via "$1"
# it is the same as $1.
function _Dbg_esc_dq {
  builtin printf "%q\n" "$1"
}

# Print "on" or "off" depending on whether $1 is true (0) or false
# (nonzero).
function _Dbg_onoff {
  typeset onoff='off.'
  (( $1 != 0 )) && onoff='on.'
  builtin echo $onoff
}

# Set $? to $1 if supplied or the saved entry value of $?. 
function _Dbg_set_dol_q {
  return ${1:-$_Dbg_debugged_exit_code}
}

# Split $2 using $1 as the split character.  We accomplish this by
# temporarily resetting the variable IFS (input field separator).
#
# Example:
# typeset -a a=($(_Dbg_split ':' "file:line"))
# a[0] will have file and a{1] will have line.

function _Dbg_split {
  typeset old_IFS=$IFS
  typeset new_ifs=${1:-' '}
  shift
  typeset -r text="$*"
  typeset -a array
  IFS="$new_ifs"
  array=( $text )
  echo ${array[@]}
  IFS=$old_IFS
}

# Return value of eval($1$2). Until bash has associative arrays,
# this is how we simulate such a datatype. In Perl this would be returning
# the value of  $1{$2}.

function _Dbg_get_assoc_scalar_entry {
    typeset prefix=$1
    typeset entry=${2:-''}
    typeset cmd="echo \$${prefix}${entry}"
    eval $cmd
}

# Set eval($1$2)=$2. Until bash has associative arrays,
# this is how we simulate such a datatype. In Perl this would be
# $1{$2}=$3.

function _Dbg_set_assoc_scalar_entry {
  typeset prefix=$1
  typeset entry=$2
  typeset value=$3
  typeset cmd="${prefix}${entry}=$value"
  eval $cmd

  typeset dq_value=$(_Dbg_esc_dq "$value")
  _Dbg_write_journal "${prefix}${entry}=\"$dq_value\""

}

# Return value of eval($1[$2]). If $2 is omitted, use _curline.  Until
# bash has associative arrays which can contain array elements this is
# how we simulate such a datatype.

function _Dbg_get_assoc_array_entry {
  typeset prefix=$1
  typeset lineno=${2:-$_curline}

  [[ -z $prefix ]] && _Dbg_msg "Internal debug error (gae) bad prefix"
  typeset entry="$prefix[$lineno]"
  typeset cmd="echo \"\${$entry}\""
  eval $cmd
}

# Evaluate eval($1[$2]=$3). If $2 is omitted, use _curline.  Until
# bash has associative arrays cich can contain array elements this is
# how we simulate such a datatype.

function _Dbg_set_assoc_array_entry {
  typeset prefix=$1
  typeset lineno=$2
  shift; shift
  typeset value=$*
  
  [[ -z "$prefix" ]] && _Dbg_msg "Internal debug error (sae1) bad prefix"
  [[ -z "$lineno" ]] && _Dbg_msg "Internal debug error (sae2) bad lineno"
  [[ -z "$value" ]] && _Dbg_msg "Internal debug error (sae3) bad value"

  typeset entry="$prefix[$lineno]"
  typeset cmd="$entry=\"$value\""
  eval $cmd

  typeset dq_value=$(_Dbg_esc_dq "$value")
  _Dbg_write_journal "$entry=\"$dq_value\""
}

# _get_function echoes a list of all of the functions.
# if $1 is nonzero, system functions, i.e. those whose name starts with
# an underscore (_), are included in the search.
# FIXME add parameter search pattern.
_Dbg_get_functions() {
    typeset -i include_system=${1:-0}
    typeset    pat=${2:-*}
    typeset -a fns_a
    fns_a=( $(declare -F) )
    typeset -a ret_fns=()
    typeset -i i
    typeset -i invert=0;

    if [[ $pat == !* ]] ; then 
	# Remove leading !
	pat=#{$pat#!}
	invert=1
    fi	

    # Iterate skipping over consecutive single tokens "declare" and "-F"
    for (( i=2; (( i < ${#fns_a[@]} )) ; i += 3 )) ; do
	typeset fn="${fns_a[$i]}"
	[[ $fn == _* ]] && (( ! $include_system )) && continue
	if [[ $fn == $pat ]] ; then 
	     [[ $invert == 0 ]] && ret_fns[${#ret_fns[@]}]=$fn
	else
	     [[ $invert != 0 ]] && ret_fns[${#ret_fns[@]}]=$fn
	fi

    done
    echo ${ret_fns[@]}
}

# _Dbg_is_function returns 0 if $1 is a defined function or nonzero otherwise. 
# if $2 is nonzero, system functions, i.e. those whose name starts with
# an underscore (_), are included in the search.
_Dbg_is_function() {
    (( 0 == $# )) && return 1
    typeset needed_fn=$1
    typeset -i include_system=${2:-0}
    [[ ${needed_fn:0:1} == '_' ]] && ((!include_system)) && {
	return 1
    }
    declare -F $needed_fn >/dev/null 2>&1
    return $?
}

# Return 0 if set -x tracing is on
_Dbg_is_traced() {
    # Is "x" in set options? 
    if [[ $- == *x* ]] ; then
	return 0
    else
	return 1
    fi
}

# Common routine for setup of commands that take a single
# linespec argument. We assume the following variables 
# which we store into:
#  filename, line_number, full_filename

function _Dbg_linespec_setup {
  typeset linespec=${1:-''}
  if [[ -z $linespec ]] ; then
    _Dbg_errmsg "Invalid line specification, null given"
  fi
  typeset -a word
  eval "word=($(_Dbg_parse_linespec $linespec))"
  if [[ ${#word[@]} == 0 ]] ; then
    _Dbg_errmsg "Invalid line specification: $linespec"
    return
  fi
  
  filename="${word[2]}"
  typeset -ir is_function=${word[1]}
  line_number=${word[0]}
  full_filename=$(_Dbg_is_file "$filename")

  if (( is_function )) ; then
      if [[ -z $full_filename ]] ; then 
	  _Dbg_readin "$filename"
	  full_filename=$(_Dbg_is_file "$filename")
      fi
  fi
}

# Parse linespec in $1 which should be one of
#   int
#   file:line
#   function-num
# Return triple (line,  is-function?, filename,)
# We return the filename last since that can have embedded blanks.
function _Dbg_parse_linespec {
  typeset linespec=$1
  eval "$_seteglob"
  case "$linespec" in

    # line number only - use _Dbg_frame_last_filename for filename
    $int_pat )	
      echo "$linespec 0 \"$_Dbg_frame_last_filename\""
      ;;
    
    # file:line
    [^:][^:]*[:]$int_pat )
      # Split the POSIX way
      typeset line_word=${linespec##*:}
      typeset file_word=${linespec%${line_word}}
      file_word=${file_word%?}
      echo "$line_word 0 \"$file_word\""
      ;;

    # Function name or error
    * )
      if _Dbg_is_function $linespec $_Dbg_debug_debugger ; then 
	local -a word=( $(declare -F $linespec) )
	if [[ $? && ${#word[@]} > 2 ]]; then 
	  builtin echo "${word[1]} 1 ${word[2]}"
	else
	  builtin echo ''
	fi
      else  
	builtin echo ''
      fi
      ;;
   esac
}

# usage _Dbg_set_ftrace [-u] funcname [funcname...]
# Sets or unsets a function for stopping by setting 
# the -t or +t property to the function declaration.
#
function _Dbg_set_ftrace {
  typeset opt=-t tmsg="enabled" func 
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

# This is put at the end so we have something at the end when we debug this.
[[ -z $_Dbg_fns_ver ]] && typeset -r _Dbg_fns_ver=\
'$Id: fns.sh,v 1.8 2008/10/18 10:27:16 rockyb Exp $'
