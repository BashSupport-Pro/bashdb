# -*- shell-script -*-
#   Copyright (C) 2008 Rocky Bernstein rocky@gnu.org
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

# Command aliases are stored here.
typeset -a _Dbg_alias_names=()
typeset -a _Dbg_alias_expansion=()
typeset -i _Dbg_alias_max_index=-1

# Add an new alias in the alias table
_Dbg_alias_add() {
    (( $# != 2 )) && return 1
    ((_Dbg_alias_max_index++))
    _Dbg_alias_names+=("$1")
    _Dbg_alias_expansion+=("$2")
     return 0
}

# Remove alias $1 from our list of command aliases.
_Dbg_alias_remove() {
    (( $# != 1 )) && return 1
    typeset -i i
    if i=$(_Dbg_alias_find_index "$1") ; then
      unset "_Dbg_alias_names[$i]"
      unset "_Dbg_alias_expansion[$i]"
      return 0
    else
      return 1
    fi
}

# Expand alias $1. The result is set in variable expanded_alias which
# could be declared local in the caller.
_Dbg_alias_expand() {
    (( $# != 1 )) && return 1
    expanded_alias=$1
    typeset -i i
    i=$(_Dbg_alias_find_index "$1")
    (( $? == 0 )) && [[ -n ${_Dbg_alias_expansion[$i]} ]] && expanded_alias=${_Dbg_alias_expansion[$i]}
    return 0
}

# Return the index in _Dbg_command_names of $1 or -1 if not there.
_Dbg_alias_find_index() {
    typeset find_name=$1
    typeset -i i
    for ((i=0; i <= $_Dbg_alias_max_index; i++)) ; do
	[[ ${_Dbg_alias_names[i]} == "$find_name" ]] && echo $i && return 0
    done
    return 1
}

# Return in help_aliases an array of strings that are aliases
# of $1
_Dbg_alias_find_aliased() {
    (($# != 1)) &&  return 255
    typeset find_name=$1
    aliases_found=''
    typeset -i i
    for ((i=0; i <= $_Dbg_alias_max_index; i++)) ; do
	if [[ ${_Dbg_alias_expansion[i]} == "$find_name" ]] ; then 
	    [[ -n $aliases_found ]] && aliases_found+=', '
	    aliases_found+=${_Dbg_alias_names[i]}
	fi
    done
    return 0
    
}

