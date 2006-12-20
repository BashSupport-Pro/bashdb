# dbg-stack.inc - Bourne Again Shell Debugger Call Stack routines
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006 Rocky Bernstein
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

# The top number items on the FUNCNAME stack are debugging routines
# Set the index in FUNCNAME that should be reported as index 0 (or top).
typeset -ir _Dbg_STACK_TOP=2

# Where are we in stack? This can be changed by "up", "down" or "frame"
# commands. On debugger entry, the value is set to _Dbg_STACK_TOP.
typeset -i  _Dbg_stack_pos   

#======================== FUNCTIONS  ============================#

_Dbg_adjust_frame() {
  local -i count=$1
  local -i signum=$2

  local -i retval
  _Dbg_stack_int_setup $count
  (( retval )) && return

  local -i pos
  if (( signum==0 )) ; then
    if (( count < 0 )) ; then
      ((pos=${#FUNCNAME[@]}-3+count))
    else
      ((pos=_Dbg_STACK_TOP+count))
    fi
  else
    ((pos=_Dbg_stack_pos+(count*signum)))
  fi
    
  if (( pos <= _Dbg_STACK_TOP-1 )) ; then 
    _Dbg_msg "Would be beyond bottom-most (most recent) entry."
    return
  elif (( pos >= ${#FUNCNAME[@]}-3 )) ; then 
    _Dbg_msg "Would be beyond top-most (least recent) entry."
    return
  fi

  ((_Dbg_stack_pos = pos))
  local -i j=_Dbg_stack_pos+2
  _Dbg_listline=${BASH_LINENO[$j]}
  ((j++))
  _cur_source_file=${BASH_SOURCE[$j]}
  _Dbg_print_source_line $_Dbg_listline

}

# Tests for a signed integer parameter and set global retval
# if everything is okay. Retval is set to 1 on error
_Dbg_stack_int_setup() {

  if (( ! _Dbg_running )) ; then
    _Dbg_msg "No stack."
    retval=1
  else
    eval "$_seteglob"
    if [[ $1 != '' && $1 != $signed_int_pat ]] ; then 
      _Dbg_msg "Bad integer parameter: $1"
      retval=1
    fi
    eval "$_resteglob"
  fi
}

# Move default values down $1 or one in the stack. 

_Dbg_do_down() {
  local -i count=${1:-1}
  _Dbg_adjust_frame $count -1
}

_Dbg_do_frame() {
  local -i pos=${1:-0}
  _Dbg_adjust_frame $pos 0
}

# Print a stack trace.  
# $1 is an additional offset correction - this routine is called from two
# different places and one routine has one more additional call on top.
# $2 is the maximum number of entries to include.
# $3 is which entry we start from; the "up", "down" and the "frame"
# commands may shift this.

# This code assumes the's debugger version of bash where FUNCNAME is
# an array, not a variable.

_Dbg_do_stack_trace() {

  if (( ! _Dbg_running )) ; then
      _Dbg_msg "No stack."
      return
  fi

  local -i n=${#FUNCNAME[@]}-1

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
    _Dbg_msg "$prefix$k in file \`$filename' at line $_curline"
    
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
    (( i == _Dbg_stack_pos+1 )) && prefix='->'
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

# Print info args. Like GDB's "info args"
# $1 is an additional offset correction - this routine is called from two
# different places and one routine has one more additional call on top.
# This code assumes the's debugger version of
# bash where FUNCNAME is an array, not a variable.

_Dbg_do_info_args() {

  local -i n=${#FUNCNAME[@]}-1

  eval "$_seteglob"
  if [[ $1 != $int_pat ]] ; then 
    _Dbg_msg "Bad integer parameter: $1"
    eval "$_resteglob"
    return 1
  fi

  local -i i=_Dbg_stack_pos+$1

  (( i > n )) && return 1

  # Figure out which index in BASH_ARGV is position "i" (the place where
  # we start our stack trace from). variable "r" will be that place.

  local -i q
  local -i r=0
  for (( q=0 ; q<i ; q++ )) ; do 
    (( r = r + ${BASH_ARGC[$q]} ))
  done

  # Print out parameter list.
  if (( 0 != ${#BASH_ARGC[@]} )) ; then

    local -i arg_count=${BASH_ARGC[$i]}

    ((r += arg_count - 1))

    local -i s
    for (( s=1; s <= arg_count ; s++ )) ; do 
      _Dbg_printf "$%d = %s" $s "${BASH_ARGV[$r]}"
      ((r--))
    done
  fi
  return 0
}

# Move default values up $1 or one in the stack. 

_Dbg_do_up() {
  local -i count=${1:-1}
  _Dbg_adjust_frame $count +1
}

# This is put at the so we have something at the end when we debug this.
_Dbg_stack_ver='$Id: dbg-stack.inc,v 1.6 2006/12/20 07:49:50 rockyb Exp $'

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
