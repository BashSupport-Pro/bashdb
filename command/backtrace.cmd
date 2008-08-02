# -*- shell-script -*-
# backtrace.cmd - gdb-like backtrace debugger command
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008 Rocky Bernstein
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

# Print a stack backtrace.  
# $1 is an additional offset correction - this routine is called from two
# different places and one routine has one more additional call on top.
# $2 is the maximum number of entries to include.
# $3 is which entry we start from; the "up", "down" and the "frame"
# commands may shift this.

# This code assumes the version of bash where FUNCNAME is an array,
# not a variable.

_Dbg_do_backtrace() {

  if (( ! _Dbg_running )) ; then
      _Dbg_msg "No stack."
      return
  fi

  local -i n=${#FUNCNAME[@]}-1 # remove us (_Dbg_do_info_args) from count

  eval "$_seteglob"
  if [[ $1 != $int_pat ]] ; then 
    _Dbg_msg "Bad integer parameter: $1"
    eval "$_resteglob"
    return 1
  fi
  if [[ $2 != '' && $2 != $int_pat ]] ; then 
    _Dbg_msg "Bad integer parameter: $2"
    eval "$_resteglob"
    return 1
  fi
  eval "$_resteglob"

  local prefix='##'
  local -i count=${2:-$n}
  local -i k=${3:-0}
  local -i i=_Dbg_STACK_TOP+k+$1
  local -i j=i

  (( j > n )) && return 1
  (( i == _Dbg_stack_pos+$1 )) && prefix='->'
  if (( k == 0 )) ; then
    local filename=${BASH_SOURCE[$i]}
    (( _Dbg_basename_only )) && filename=${filename##*/}
    _Dbg_print_frame "$prefix" "$k" '' "$filename" "$_curline" ''
    ((count--)) ; ((k++))
  fi

  # Figure out which index in BASH_ARGV is position "i" (the place where
  # we start our stack trace from). variable "r" will be that place.

  local -i q
  local -i r=0
  for (( q=0 ; q<i ; q++ )) ; do 
    (( r = r + ${BASH_ARGC[$q]} ))
  done

  # Loop which dumps out stack trace.
  for ((  ; (( i <= n && count > 0 )) ; i++ )) ; do 
    local -i arg_count=${BASH_ARGC[$i]}
    ((j++)) ; ((count--))
    prefix='##'
    (( i == _Dbg_stack_pos+$1-1)) && prefix='->'
    if (( i == n )) ; then 
      # main()'s file is the same as the first caller
      j=i  
    fi

    _Dbg_msg_nocr "$prefix$k ${FUNCNAME[$i]}("

    local parms=''

    # Print out parameter list.
    if (( 0 != ${#BASH_ARGC[@]} )) ; then
      local -i s
      for (( s=0; s < arg_count; s++ )) ; do 
	if (( s != 0 )) ; then 
	  parms="\"${BASH_ARGV[$r]}\", $parms"
	elif [[ ${FUNCNAME[$i]} == "source" ]] \
	  && (( _Dbg_basename_only )); then
	  local filename=${BASH_ARGV[$r]}
	  filename=${filename##*/}
	  parms="\"$filename\""
	else
	  parms="\"${BASH_ARGV[$r]}\""
	fi
	((r++))
      done
    fi

    local filename=${BASH_SOURCE[$j]}
    (( _Dbg_basename_only )) && filename=${filename##*/}
    _Dbg_msg "$parms) called from file \`$filename'" \
      "at line ${BASH_LINENO[$i]}"
    ((k++))
  done
  return 0
}

