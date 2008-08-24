# -*- shell-script -*-
# tty command.
#
#   Copyright (C) 2002, 2003, 2004, 2006, 2008 Rocky Bernstein 
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

_Dbg_help_add tty \
'tty -- Set the output device for debugger output.'

# Set output tty
_Dbg_do_tty() {
  if [[ -z "$1" ]] ; then
    _Dbg_msg "Argument required (terminal name for running target process)."
    return 1
  fi
  if ! $(touch $1 >/dev/null 2>/dev/null); then 
    _Dbg_msg "Can't access $1 for writing."
    return 1
  fi
  if [[ ! -w $1 ]] ; then
    _Dbg_msg "tty $1 needs to be writable"
    return 1
  fi
  _Dbg_tty=$1
  return 0
}
