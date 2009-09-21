# -*- shell-script -*-
# source command.
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

# Handle command-file source. If the filename's okay we just increase the
# input-file descriptor by one and redirect input which will
# be picked up in next debugger command loop.

_Dbg_help_add source \
'source FILE -- Run debugger commands in FILE.'

_Dbg_do_source() {
  if (( $# == 0 )) ; then
    _Dbg_errmsg 'Need to give a filename for the "source" command'
    return 1
  fi

  typeset filename
  _Dbg_glob_filename "$1"
  if [[ -r $filename ]] || [[ "$filename" == '/dev/stdin' ]] ; then
    if ((_Dbg_input_desc < _Dbg_MAX_INPUT_DESC )) ; then 
      ((_Dbg_input_desc++))
      _Dbg_input[$_Dbg_input_desc]=$filename
      typeset _Dbg_redirect_cmd="exec $_Dbg_input_desc<\"$filename\""
      eval $_Dbg_redirect_cmd
      _Dbg_cmdfile[${#_Dbg_cmdfile[@]}]=$filename
    else 
      typeset -i max_nesting
      ((max_nesting=_Dbg_MAX_INPUT_DESC-_Dbg_INPUT_START_DESC+1))
      _Dbg_errmsg "Source nesting too deep; nesting can't be greater than $max_nesting."
      return 2
    fi
  else
    _Dbg_errmsg "Source file \"$filename\" is not readable."
    return 3
  fi
  return 0
}
