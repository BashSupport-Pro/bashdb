# -*- shell-script -*-
# "set filename-display" debugger command
#
#   Copyright (C) 2011, 2014, 2016, 2020 Rocky Bernstein <rocky@gnu.org>
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

_Dbg_help_add_sub set "filename-display" \
'**set filename-display** [**basename**|**absolute**]

Set how to display filenames: absolute paths or the basename only.

See also:
---------

**show filename-display**
'

_Dbg_do_set_filename_display() {
    typeset arg=${1:-'absolute'}
    # FIXME? convert to more gdb-like output
    case $arg in
        b | ba | bas | base | basen | basena | basenam | basename )
	    _Dbg_set_basename=1
            ;;
        a | ab | abs | abso | absol | absolu | absolut | absolute )
	    _Dbg_set_basename=0
            ;;
        * )
            _Dbg_errmsg '"absolute" or "basename" expected.'
            return 0
    esac
    _Dbg_do_show_filename_display
    return 0
}
