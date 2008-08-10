# -*- shell-script -*-
# stack.sh - Bourne Again Shell Debugger Call Stack routines
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
  _Dbg_stack_int_setup $count || return

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
    _Dbg_msg 'Would be beyond bottom-most (most recent) entry.'
    return 1
  elif (( pos >= ${#FUNCNAME[@]}-3 )) ; then 
    _Dbg_msg 'Would be beyond top-most (least recent) entry.'
    return 1
  fi

  ((_Dbg_stack_pos = pos))
  local -i j=_Dbg_stack_pos+2
  _Dbg_listline=${BASH_LINENO[$j]}
  ((j++))
  _cur_source_file=${BASH_SOURCE[$j]}
  _Dbg_print_source_line $_Dbg_listline
  return 0
}

# Tests for a signed integer parameter and set global retval
# if everything is okay. Retval is set to 1 on error
_Dbg_stack_int_setup() {

  if (( ! _Dbg_running )) ; then
    _Dbg_errmsg 'No stack.'
    return 1
  else
    eval "$_seteglob"
    if [[ $1 != '' && $1 != $signed_int_pat ]] ; then 
      _Dbg_msg "Bad integer parameter: $1"
      eval "$_resteglob"
      return 1
    fi
    eval "$_resteglob"
    return 0
  fi
}

# Print one line in a call stack
_Dbg_print_frame() {
    typeset prefix=$1
    typeset -i pos=$2
    typeset fn=$3
    typeset filename="$4"
    typeset -i line=$5
    typeset args="$6"
    typeset callstr=$fn
    [[ -n $args ]] && callstr="$callstr($args)"
    _Dbg_msg "$prefix$pos in file \`$filename' at line $line"
}

# Print info args. Like GDB's "info args"
# $1 is an additional offset correction - this routine is called from two
# different places and one routine has one more additional call on top.
# This code assumes the's debugger version of
# bash where FUNCNAME is an array, not a variable.

_Dbg_do_info_args() {

  local -i n=${#FUNCNAME[@]}-1  # remove us (_Dbg_do_info_args) from count

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

# This is put at the so we have something at the end when we debug this.
_Dbg_stack_ver='$Id: frame.sh,v 1.1 2008/08/10 22:25:08 rockyb Exp $'
