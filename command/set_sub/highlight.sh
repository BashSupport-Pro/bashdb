# -*- shell-script -*-
# "set highlight" debugger command
#
#   Copyright (C) 2011, 2014 Rocky Bernstein <rocky@gnu.org>
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

if [[ $0 == ${BASH_SOURCE[0]} ]] ; then
    dirname=${BASH_SOURCE[0]%/*}
    [[ $dirname == $0 ]] && top_dir='..' || top_dir=${dirname}/..
    for file in help alias ; do source $top_dir/lib/${file}.sh; done
fi

_Dbg_help_add_sub set highlight \
'set highlight [on|off|reset]

Set using terminal highlight.

Use "reset" to set highlighting on and force a redo of syntax
highlighting of already cached files. This may be needed if the
debugger was started without syntax highlighting initially.

See also: show highlight.' 1

_Dbg_next_complete[set highlight]='_Dbg_complete_edit'

_Dbg_complete_highlight() {
    COMPREPLY=(on off reset)
}

_Dbg_do_set_highlight() {
    if ( pygmentize --version || pygmentize -V ) 2>/dev/null 1>/dev/null ; then
	:
    else
	_Dbg_errmsg "Can't run pygmentize. Setting forced off"
	return 1
    fi
    typeset onoff=${1:-'on'}
    case $onoff in
	on | 1 )
	    _Dbg_set_highlight=1
	    ;;
	off | 0 )
	    _Dbg_set_highlight=0
	    ;;
	reset )
	    _Dbg_set_highlight=1
	    _Dbg_filecache_reset
	    _Dbg_readin $_Dbg_frame_last_filename
	    ;;
	* )
	    _Dbg_errmsg '"on", "off", or "reset" expected.'
	    return 1
    esac
    _Dbg_do_show highlight
    return 0
}
