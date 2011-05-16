# -*- shell-script -*-
#
#   Copyright (C) 2008, 2010, 2011 Rocky Bernstein <rocky@gnu.org>
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

_Dbg_help_add untrace \
'untrace FUNCTION

Undo prior trace of FUNCTION. See also "trace".'

# Undo wrapping fn
# $? is 0 if successful.
function _Dbg_do_untrace {
    typeset -r fn=$1
    if [[ -z $fn ]] ; then
	_Dbg_errmsg "untrace_fn: missing or invalid function name."
	return 2
    fi
    _Dbg_is_function "$fn" || {
	_Dbg_errmsg "untrace_fn: function \"$fn\" is not a function."
	return 3
    }
    _Dbg_is_function "old_$fn" || {
	_Dbg_errmsg "untrace_fn: old function old_$fn not seen - nothing done."
	return 4
    }
    cmd=$(declare -f -- "old_$fn") || return 5
    cmd=${cmd#old_}
    ((_Dbg_set_debug)) && echo $cmd 
    eval "$cmd" || return 6
    return 0
}
