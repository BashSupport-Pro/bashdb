# -*- shell-script -*-
# frame.sh - Call Stack routines
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008, 2009 Rocky Bernstein
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
typeset -i _Dbg_STACK_TOP=2

# Where are we in stack? This can be changed by "up", "down" or "frame"
# commands. On debugger entry, the value is set to _Dbg_STACK_TOP.
typeset -i  _Dbg_stack_pos   

#======================== FUNCTIONS  ============================#

_Dbg_frame_adjust() {
  (($# != 2)) && return 255

  typeset -i count=$1
  typeset -i signum=$2

  typeset -i retval
  _Dbg_frame_int_setup $count || return 2

  typeset -i pos
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
    _Dbg_errmsg 'Would be beyond bottom-most (most recent) entry.'
    return 1
  elif (( pos >= ${#FUNCNAME[@]}-3 )) ; then 
    _Dbg_errmsg 'Would be beyond top-most (least recent) entry.'
    return 1
  fi

  ((_Dbg_stack_pos = pos))
  typeset -i j=_Dbg_stack_pos+2
  _Dbg_listline="${BASH_LINENO[$j]}"
  ((j++))
  _Dbg_frame_last_filename="${BASH_SOURCE[$j]}"
  _Dbg_print_location_and_command "$_Dbg_listline"
  return 0
}

# Tests for a signed integer parameter and set global retval
# if everything is okay. Retval is set to 1 on error
_Dbg_frame_int_setup() {

  _Dbg_not_running && return 1
  eval "$_seteglob"
  if [[ $1 != '' && $1 != $signed_int_pat ]] ; then 
      _Dbg_errmsg "Bad integer parameter: $1"
      eval "$_resteglob"
      return 1
  fi
  eval "$_resteglob"
  return 0
}

_Dbg_frame_lineno() {
    _Dbg_frame_lineno=$_curline
    return $Dbg_frame_lineno
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
