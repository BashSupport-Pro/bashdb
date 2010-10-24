# -*- shell-script -*-
# "show alias" debugger command
#
#   Copyright (C) 2010 Rocky Bernstein rocky@gnu.org
#
#   zshdb is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   zshdb is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with zshdb; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

_Dbg_do_show_alias() {
    typeset -a list
    typeset -i i
    list=()
    for ((i=0; i<=_Dbg_alias_max_index; i++)) ; do
	[[ -z ${_Dbg_alias_names[i]} ]] && continue
	list+=("${_Dbg_alias_names[i]}: ${_Dbg_alias_expansion[i]}")
    done
    _Dbg_list_columns '  |  '
    return 0
}
