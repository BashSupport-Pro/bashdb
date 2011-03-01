# -*- shell-script -*-
# shell.sh - helper routines for 'shell' debugger command
#
#   Copyright (C) 2011 Rocky Bernstein <rocky@gnu.org>
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

_Dbg_shell_write_vars() {
    typeset -a _Dbg_variable_parameters=()
    typeset -a words 
    typeset -p | while read -a words ; do 
	[[ declare != ${words[0]} ]] && continue
	var_name=${words[2]%%=*}
	# ((_Dbg_set_debugging)) && 
	[[ $var_name =~ ^_Dbg_ ]] && continue	
	flags=${words[1]}
	if [[ $flags =~ ^-.*x ]]; then 
	    # Skip exported varables
	    continue
	elif [[ $flags =~ -.*r ]]; then 
	    # handle read-only variables
	    echo "typeset -p ${var_name} &>/dev/null || $(typeset -p ${var_name})"
	elif [[ ${flags:0:1} == '-' ]] ; then
	    echo $(typeset -p ${var_name})
	fi
    done >>$_Dbg_shell_temp_profile
}
