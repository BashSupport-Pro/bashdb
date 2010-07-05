# -*- shell-script -*-
# where.sh - gdb-like "bt", "where", or "bt" backtrace debugger command
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008, 2010 Rocky
#   Bernstein rocky@gnu.org
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

# Print a stack backtrace.  
# $1 is an additional offset correction - this routine is called from two
# different places and one routine has one more additional call on top.
# $2 is the maximum number of entries to include.
# $3 is which entry we start from; the "up", "down" and the "frame"
# commands may shift this.

# This code assumes the version of bash where FUNCNAME is an array,
# not a variable.

_Dbg_help_add where \
"where [COUNT [FRAME-INDEX]] 

Print a backtrace of calling functions and sourced files.

The backtrace contains function names, arguments, line numbers, and
files. If COUNT is given, list only COUNT calls. If IGNORE-TOP is
given that many frame entries are ignored"

# FIXME: $1 is a hidden parameter not shown in help. $2 is COUNT.
# $3 is FRAME-INDEX.
function _Dbg_do_backtrace {

    _Dbg_not_running && return 1
    
    typeset -il count=${1:-$_Dbg_stack_size}
    $(_Dbg_is_int $count) || {
	_Dbg_errmsg "Bad integer COUNT parameter: $count"
	return 1
    }
    
    typeset -il frame_start=${2:-0}

    $(_Dbg_is_int $frame_start) || {
	_Dbg_errmsg "Bad integer parameter: $ignore_count"
	return 1
    }
    
    # i is the logical frame value - 0 most recent frame.
    typeset -il i=frame_start
    
    # Figure out which index in BASH_ARGV is position "i" (the place where
    # we start our stack trace from). variable "r" will be that place.

    typeset -i q
    typeset -i r=0
    for (( q=0 ; q<=k ; q++ )) ; do 
	[[ -z ${BASH_ARGC[$q]} ]] && break
	(( r = r + ${BASH_ARGC[$q]} ))
    done

    ## DEBUG
    ##  typeset -p BASH_ARGC
    ## typeset -p BASH_ARGV
    ## typeset -p r

    typeset -li adjusted_pos
    
    ## DEBUG
    ## typeset -p pos
    ## typeset -p BASH_LINENO
    ## typeset -p BASH_SOURCE
    ## typeset -p FUNCNAME

    typeset -l  filename
    typeset -li adjusted_pos
    # Position 0 is special in that get the line number not from the
    # stack but ultimately from LINENO which was saved in the hook call.
    if (( frame_start == 0 )) ; then
	((count--)) ; 
	adjusted_pos=$(_Dbg_frame_adjusted_pos 0)
	filename=$(_Dbg_file_canonic "${BASH_SOURCE[$adjusted_pos]}")
	_Dbg_print_frame $(_Dbg_frame_prefix 0) '0' '' "$filename" "$_Dbg_frame_last_lineno" ''
    fi

    # Loop which dumps out stack trace.
    for ((  i=frame_start+1 ; 
	    i <= _Dbg_stack_size && count > 0 ;
	    i++ )) ; do 
	typeset -il arg_count=${BASH_ARGC[$r]}
	adjusted_pos=$(_Dbg_frame_adjusted_pos $i)
	_Dbg_msg_nocr $(_Dbg_frame_prefix $i)$i ${FUNCNAME[$adjusted_pos-1]}'('
	
	typeset parms=''
	
	# Print out parameter list.
	if (( 0 != ${#BASH_ARGC[@]} )) ; then
	    typeset -i s
	    for (( s=0; s < arg_count; s++ )) ; do 
		if (( s != 0 )) ; then 
		    parms="\"${BASH_ARGV[$r]}\", $parms"
		elif [[ ${FUNCNAME[$i]} == "source" ]] ; then
		    parms=\"$(_Dbg_file_canonic "${BASH_ARGV[$r]}")\"
		else
		    parms="\"${BASH_ARGV[$r]}\""
		fi
		((r++))
	    done
	fi
	
	filename=$(_Dbg_file_canonic "${BASH_SOURCE[$adjusted_pos-1]}")
	_Dbg_msg "$parms) called from file \`$filename'" \
	    "at line ${BASH_LINENO[$adjusted_pos-1]}"

	((count--))
    done
    return 0
}

_Dbg_alias_add 'T' 'where'
_Dbg_alias_add 'backtrace' 'where'
_Dbg_alias_add 'bt' 'where'
