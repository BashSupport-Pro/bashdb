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

# Wrap "set -x .. set +x" around a call to function $1.
# The wrapped function becomes the new function and the original
# function is called old_$1.
# $? is 0 if successful.
function _Dbg_do_trace_fn {
    typeset -r fn=$1
    if [[ -z $fn ]] ; then
	_Dbg_msg "trace_fn: missing function name"
	return 2
    fi
    _Dbg_is_function? "$fn" || {
	_Dbg_msg "trace_fn: function \"$fn\" is not a function."
	return 3
    }
    cmd=old_$(declare -f $fn) || {
	return 4
    }
    (($debug)) && echo $cmd 
    eval "$cmd" || return 5
    cmd="${fn}() { 
    set -x; 
    old_$fn \$*; 
    set +x
    }
"
    ((_Dbg_debug_debugger)) && echo $cmd 
    eval "$cmd" || return 6
    return 0
}

# Undo wrapping fn
# $? is 0 if successful.
function _Dbg_do_untrace_fn {
    typeset -r fn=$1
    if [[ -z $fn ]] ; then
	_Dbg_msg "untrace_fn: missing function name."
	return 2
    fi
    _Dbg_is_function? "$fn" || {
	_Dbg_msg "untrace_fn: function \"$fn\" is not a function."
	return 3
    }
    _Dbg_is_function? "old_$fn" || {
	_Dbg_msg "untrace_fn: old function old_$fn not seen - nothing done."
	return 4
    }
    cmd=$(declare -f old_$fn) || return 5
    cmd=${cmd#old_}
    ((_Dbg_debug_debugger)) && echo $cmd 
    eval "$cmd" || return 6
    return 0
}

# This is put at the end so we have something at the end when we debug this.
[[ -z $_Dbg_fns_ver ]] && typeset -r _Dbg_tracefns_ver=\
'$Id: dbg-tracefn.inc,v 1.1 2008/06/05 09:51:50 rockyb Exp $'

