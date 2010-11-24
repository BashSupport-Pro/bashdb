# -*- shell-script -*-
# help.sh - gdb-like "help" debugger command
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008, 2010 Rocky Bernstein
#   <rocky@gnu.org>
#
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation; either version 2, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; see the file COPYING.  If not, write to
#   the Free Software Foundation, 59 Temple Place, Suite 330, Boston,
#   MA 02111 USA.

_Dbg_help_add help \
'help	-- Print list of commands.'

# print help command 
function _Dbg_do_help {

    # We have to use be careful to make sure globbing, e.g. * isn't
    # done.

    # Treat "help *" the same as help
    [[ "$_Dbg_args" == '*' ]] && _Dbg_args=''

    if [[ '' == $_Dbg_args ]] ; then
      _Dbg_help_sort_command_names
      _Dbg_msg 'Available commands:'
      typeset -a list=("${_Dbg_sorted_command_names[@]}")
      _Dbg_list_columns
      _Dbg_msg ''
      _Dbg_msg 'Readline command line editing (emacs/vi mode) is available.'
      _Dbg_msg 'Type "help" followed by command name for full documentation.'
      return 0
    else
	typeset dbg_cmd="$1"
	if [[ -n ${_Dbg_command_help[$dbg_cmd]} ]] ; then
 	    _Dbg_msg "${_Dbg_command_help[$dbg_cmd]}"
	else
	    _Dbg_alias_expand $dbg_cmd
	    dbg_cmd="$expanded_alias"
	    if [[ -n ${_Dbg_command_help[$dbg_cmd]} ]] ; then
 		_Dbg_msg "${_Dbg_command_help[$dbg_cmd]}"
	    else
		case $dbg_cmd in 
		    i | in | inf | info )
			_Dbg_info_help $2
			;;
		    sh | sho | show )
			_Dbg_help_show $2
			;;
		    se | set )
			_Dbg_help_set $2
			;;
		    * )
  			_Dbg_errmsg "Undefined command: \"$dbg_cmd\".  Try \"help\"."
  			return 1 ;;
		esac
	    fi
	fi
	aliases_found=''
	_Dbg_alias_find_aliased "$dbg_cmd"
	if [[ -n $aliases_found ]] ; then
	    _Dbg_msg ''
	    _Dbg_msg "Aliases for $dbg_cmd: $aliases_found"
	fi
	return 2
    fi
}

_Dbg_alias_add 'h' help
