# -*- shell-script -*-
# list.sh - Some listing commands
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008, 2009, 2010,
#   2011 Rocky Bernstein <rocky@gnu.org>
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

_Dbg_help_add list \
'list[>] [LOC|.|-] [NUMBER] 

LOC is the starting location or dot (.) for current file and
line. Subsequent list commands continue from the last line
listed. Frame switching however resets the line to dot. LOC can be a
read-in function name or a filename and line number separated by a
colon, e.g /etc/profile:5

If NUMBER is omitted, use the LISTSIZE setting as a count. Use "set
listsize" to change this setting. If NUMBER is given and is less than
the starting line, then it is treated as a count. Otherwise it is
treated as an ending line number.

By default aliases "l>" and "list>" are set to list. In this case and
more generally when the alias ends in ">", rather than center lines
around LOC that will be used as the starting point.

Examples:

list .      # List centered around the curent frame line
list        # Same as above if the first time. Else start from where
            # we last left off.
list -      # list backwards from where we left off.
list> .     # list starting from the current frame line.
list  10 3  # list 3 lines centered around 10, lines 9-11
list> 10 3  # list lines 10-12
list  10 13 # list lines 10-13
list  10 -5 # list from lines to 5 lines before teh end of the file
list  /etc/profile:5  # List centered around line 5 of /etc/profile.
list  /etc/profile 5  # Same as above.
list usage  # list centered around function usage().

See also "set autolist".
'

# l [start|.] [cnt] List cnt lines from line start.
# l sub       List source code fn

_Dbg_do_list() {
    typeset -i center_line
    if [[ ${_Dbg_orig_cmd:${#_Dbg_orig_cmd}-1:1} == '>' ]] ; then
	center_line=0
    else
	center_line=1
    fi

    typeset first_arg
    if (( $# > 0 )) ; then
	first_arg="$1"
	shift
    else
	first_arg="$_Dbg_listline"
    fi

    if [[ $first_arg == '.' ]] || [[ $first_arg == '-' ]] ; then
	_Dbg_list $center_line "$_Dbg_frame_last_filename" $first_arg "$*"
	_Dbg_last_cmd="$_Dbg_cmd"
	return 0
    fi

    typeset filename
    typeset -i line_number
    typeset full_filename
    
    _Dbg_linespec_setup "$first_arg"
    
    if [[ -n $full_filename ]] ; then 
	(( line_number ==  0 )) && line_number=1
	_Dbg_check_line $line_number "$full_filename"
	(( $? == 0 )) && \
	    _Dbg_list $center_line "$full_filename" "$line_number" $*
	_Dbg_last_cmd="$_Dbg_cmd"
	return 0
    else
	_Dbg_file_not_read_in "$filename"
	return 3
    fi
}

_Dbg_alias_add l list
_Dbg_alias_add "l>" list
_Dbg_alias_add "list>" list
