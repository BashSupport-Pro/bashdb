# commmands.sh - gdb-like "commands" debugger command.
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

_Dbg_do_commands() {
  eval "$_seteglob"
  local num=$1
  local -i found=0
  case $num in
      $int_pat )
	  if [[ -z ${_Dbg_brkpt_file[$num]} ]] ; then
	      _Dbg_msg "No breakpoint number $num."
	      return 0
	  fi
	  ((found=1))
	;;
      * )
	_Dbg_msg "Invalid entry number skipped: $num"
  esac
  eval "$_resteglob"
  if (( found )) ; then 
      _Dbg_brkpt_commands_defining=1
      _Dbg_brkpt_commands_current=$num
      _Dbg_brkpt_commands_end[$num]=${#_Dbg_brkpt_commands[@]}
      _Dbg_brkpt_commands_start[$num]=${_Dbg_brkpt_commands_end[$num]}
      _Dbg_msg "Type commands for when breakpoint $found hit, one per line."
      _Dbg_prompt='>'
      return 1
  fi
}
