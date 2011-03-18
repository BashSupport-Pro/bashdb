# -*- shell-script -*-
# gdb-like "undisplay"
#
#   Copyright (C) 2002, 2003, 2006, 2007, 2008, 2009, 2010
#   Rocky Bernstein <rocky@gnu.org>
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
#   along with this Program; see the file COPYING.  If not, write to
#   the Free Software Foundation, 59 Temple Place, Suite 330, Boston,
#   MA 02111 USA.

_Dbg_help_add undisplay \
"undisplay NUM [NUM2 ...]

Remove display statement(s). When a 'display' statement is added it is
given a number. Use that number to remove the display statement.

Examples:
    undisplay 0     # Removes display statement 0
    undisplay 0 3 4 # Removes display statements 0, 3, and 4

See also 'display' and 'info display'."

_Dbg_do_undisplay() {
    typeset -i del
    
    if (( 0 == $# )) ; then
	_Dbg_errmsg 'You need to pass in some display numbers.'
	return 0
    fi
    
    for del in $@ ; do 
	if [ -n "${_Dbg_disp_exp[$del]}" ] ; then
	    _Dbg_write_journal_eval "unset _Dbg_disp_exp[$del]"
	    _Dbg_write_journal_eval "unset _Dbg_disp_enable[$del]"
	    _Dbg_msg "Display entry $del unset."
	else
	    _Dbg_msg "Display entry $del doesn't exist, so nothing done."
	fi
    done
    return 0
}
