# -*- shell-script -*-
# complete-cmds.inc - Bourne Again Shell Debugger command completion handling
#
#   Copyright (C) 2006 Rocky Bernstein rockyb@users.sourceforge.net
#
#   Bash is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   Bash is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with Bash; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

typeset -a _Dbg_matches=()

# Print a list of completions in global variable _Dbg_matches 
# for 'subcmd' that start with 'text'.
# We get the list of completions from _Dbg._*subcmd*_cmds.
# If no completion, we return the empty list.
_Dbg_subcmd_complete() {
    subcmd=$1
    text=$2
    _Dbg_matches=()
    local list=""
    cmd="list=\$_Dbg_${subcmd}_cmds"
    eval $cmd
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

_Dbg_do_complete() {
  declare -a commands=( - 
	. / a break
	cd commands complete continue condition clear
	d debug delete disable display
	D deleteall down eval enable examine
	file finish frame 
	handle help history info
	list kill next step skip print pwd quit reverse
	search set show signal source toggle tbreak tty
	up undisplay watche version window 
	A x L M R S T We )

    # set -x
    local -a args=($*)
    _Dbg_matches=()
    if (( ${#args[@]} == 2 )) ; then
      _Dbg_subcmd_complete ${args[0]} ${args[1]}
    elif (( ${#args[@]} == 1 )) ; then 
      eval "builtin compgen -W \"${commands[@]}\" ${args[0]}"
    fi  
    local -i i
    for (( i=0;  i < ${#_Dbg_matches[@]}  ; i++ )) ; do 
      _Dbg_msg ${_Dbg_matches[$i]}
    done
    # set +x
}

typeset -r _Dbg_complete_ver=\
'$Id: complete.sh,v 1.1 2008/08/08 21:17:30 rockyb Exp $'

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
