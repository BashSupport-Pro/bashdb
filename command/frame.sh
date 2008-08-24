# -*- shell-script -*-
# frame.sh - gdb-like "frame" debugger command
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

# Move default values down $1 or one in the stack. 

_Dbg_help_add down \
'down [COUNT] -- Set the call stack position down by COUNT.

If COUNT is omitted, use 1. COUNT can be any arithmetic expression.'

_Dbg_do_down() {
  _Dbg_not_running && return 1
  typeset -i count=${1:-1}
  _Dbg_frame_adjust $count -1
}

_Dbg_help_add frame \
'frame FRAME-NUM -- Move the current frame to the FRAME-NUM.

If FRAME-NUM is negative, count back from the least-recent frame; -1
is the oldest frame. FRAME-NUM can be any arithmetic expression.'

_Dbg_do_frame() {
  _Dbg_not_running && return 1
  typeset -i pos=${1:-0}
  _Dbg_frame_adjust $pos 0
}

# Move default values up $1 or one in the stack. 
_Dbg_help_add up \
'up [COUNT] -- Set the call stack position up by COUNT. 

If COUNT is omitted, use 1. COUNT can be any arithmetic expression.'

_Dbg_do_up() {
  _Dbg_not_running && return 1
  typeset -i count=${1:-1}
  _Dbg_frame_adjust $count +1
}

_Dbg_alias_add 'u' up
