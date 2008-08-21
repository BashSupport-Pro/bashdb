# -*- shell-script -*-
# handle.sh - gdb-like "handle" debugger command
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

_Dbg_help_add file \
"file FILENAME	-- Set FILENAME as the current source file."

_Dbg_do_file() {

  typeset filename
  if [[ -z "$1" ]] ; then
    _Dbg_msg "Need to give a filename for the file command"
    return
  fi
  _Dbg_glob_filename $1
  if [[ ! -f "$filename" ]] && [[ ! -x "$filename" ]] ; then
    _Dbg_errmsg "Source file $filename does not exist as a readable regular file."
    return
  fi
  typeset filevar=$(_Dbg_file2var ${BASH_SOURCE[3]})
  _Dbg_set_assoc_scalar_entry "_Dbg_file_cmd_" $filevar "$filename"
  typeset source_file="${BASH_SOURCE[3]}"
  (( _Dbg_basename_only )) && source_file=${source_file##*/}
  _Dbg_msg "File $filename will be used when $source_file is referenced."
}
