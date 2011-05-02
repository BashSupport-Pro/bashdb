# -*- shell-script -*-
# complete.sh - gdb-like command completion handling
#
#   Copyright (C) 2006, 2011 Rocky Bernstein rockyb@users.sourceforge.net
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

typeset -a _Dbg_matches=()

# Print a list of completions in global variable _Dbg_matches 
# for 'subcmd' that start with 'text'.
# We get the list of completions from _Dbg._*subcmd*_cmds.
# If no completion, we return the empty list.
_Dbg_subcmd_complete() {
    subcmd=$1
    text=$2
    _Dbg_matches=()
    typeset list=''
    if [[ $subcmd == 'set' ]] ; then 
	# Newer style
	list=${!_Dbg_command_help_set[@]}
    else
	# FIXME: Older style - eventually update these.
	cmd="list=\$_Dbg_${subcmd}_cmds"
	eval $cmd
    fi
    local -i last=0
    for word in $list ; do
        # See if $word contains $text at the beginning. We use the string
        # strip operatior '#' and check that some part of $word was stripped 
        if [[ ${word#$text} != $word ]] ; then 
            _Dbg_matches[$last]="$subcmd $word"
            ((last++))
        fi
    done
    # return _Dbg_matches
}

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
