# -*- shell-script -*-
# list.sh - Bourne Again Shell Debugger list/search commands
#   Copyright (C) 2002, 2003, 2004, 2006, 2008, 2009 Rocky Bernstein
#   rocky@gnu.org
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

# List search commands/routines

# Last search pattern used.
typeset _Dbg_last_search_pat

# current line to be listed
typeset -i _Dbg_listline

# Print source line in standard format for line $1 of filename $2.  If
# $2 is omitted, use _Dbg_frame_last_filename, if $1 is omitted use _curline.

function _Dbg_print_location_and_command {
  typeset line_number=${1:-$_curline}
  typeset filename=${2:-$_Dbg_frame_last_filename}
  typeset source_line
  _Dbg_get_source_line $line_number "$filename"
  filename=$(_Dbg_adjust_filename "$filename")
  _Dbg_msg "(${filename}:${line_number}):
${line_number}:\t${source_line}"

  # If we are at the same place in the file but the command has changed,
  # then we have multiple commands on the line. So print which one we are
  # currently at.
  if [[ $_Dbg_show_command == "on" ]] ; then
      _Dbg_msg "$_Dbg_bash_command"
  elif [[ $_Dbg_last_lineno == $_curline ]] \
    && [[ $_Dbg_last_source_file == $_Dbg_frame_last_filename ]] \
    && [[ $_Dbg_last_bash_command != $_Dbg_bash_command \
    && $_Dbg_show_command == "auto" ]] ; then
      _Dbg_msg "$_Dbg_bash_command"
  fi
}

# Print Linetrace output. We also handle output if linetrace expand
# is in effect.
_Dbg_print_linetrace() {
  typeset line_number=${1:-$_curline}
  typeset filename=${2:-"$_Dbg_frame_last_filename"}

  # Remove main + sig-handler  + print_lintrace FUNCNAMES.
  typeset -i depth=${#FUNCNAME[@]}-3  

  # If called from bashdb script rather than via "bash --debugger", 
  # we are artificially nested one deeper because of the bashdb call.
  if [[ -n $_Dbg_script ]] ; then 
    ((depth--))
  fi

  (( depth < 0 )) && return

  typeset source_line
  _Dbg_get_source_line $line_number "$filename"
  filename=$(_Dbg_adjust_filename "$filename")
  _Dbg_msg "(${filename}:${line_number}):
level $_Dbg_DEBUGGER_LEVEL, subshell $BASH_SUBSHELL, depth $depth:\t${source_line}"
  if (( _Dbg_linetrace_expand )) ; then
#    typeset expanded_source_line
#    # Replace all double quotes (") with and an escape (\")
#    typeset esc_source_line="${source_line//\"/\\\"}" 
#    _Dbg_do_eval "expanded_source_line=\"$esc_source_line\"" 2>/dev/null
     _Dbg_do_eval "expanded_source_line=\"$_Dbg_bash_command\"" 2>/dev/null
     _Dbg_msg "+ ${expanded_source_line}"
  fi

  # If we are at the same place in the file but the command has changed,
  # then we have multiple commands on the line. So print which one we are
  # currently at.
  if [[ $_Dbg_show_command == "on" ]] ; then
      _Dbg_msg "$_Dbg_bash_command"
  elif (( _Dbg_last_lineno == _curline )) \
    && [[ $_Dbg_last_source_file == $_Dbg_frame_last_filename ]] \
    && [[ $_Dbg_last_bash_command != $_Dbg_bash_command \
    && $_Dbg_show_command == "auto" ]] ; then
      _Dbg_msg "$_Dbg_bash_command"
  fi
}

# list $3 lines starting at line $2 of file $1. If $1 is '', use
# $_Dbg_frame_last_filename value.  If $3 is ommited, print $_Dbg_listsize
# lines. if $2 is omitted, use global variable $_curline.

_Dbg_list() {
    if (( $# > 0 )) ; then
	filename=$1
    else
	filename=$_Dbg_frame_last_file
    fi
    typeset filename=$_Dbg_frame_last_filename

    if [[ $2 = . ]]; then
      _Dbg_listline=$_curline
    elif [[ -n $2 ]] ; then
      _Dbg_listline=$2
    else
      _Dbg_listline=$_curline
    fi
    (( _Dbg_listline==0 && _Dbg_listline++))

    typeset -ir cnt=${3:-$_Dbg_listsize}
    typeset -ir n=$((_Dbg_listline+cnt-1))

    typeset source_line

    typeset filevar=$(_Dbg_file2var "$filename")
    typeset is_read
    is_read=`_Dbg_get_assoc_scalar_entry "_Dbg_read_" $filevar`
    [ $is_read ] || _Dbg_readin "$filename"
    typeset -i max_line=`_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $filevar`
    #   echo "debug: -- max_line: $max_line --"

    if (( _Dbg_listline > max_line )) ; then
      _Dbg_msg \
	"Line number $_Dbg_listline out of range;" \
      "$filename has $max_line lines."
      return 1
    fi

    for ((  ; (( _Dbg_listline <= n && _Dbg_listline <= max_line )) \
            ; _Dbg_listline++ )) ; do
     typeset prefix="   "
     typeset source_line
     _Dbg_get_source_line $_Dbg_listline "$filename"

     (( _Dbg_listline == _curline )) \
       && [[ $filename == $_Dbg_frame_last_filename ]] &&  prefix="==>"
     _Dbg_printf "%3d:%s%s" $_Dbg_listline "$prefix" "$source_line"
    done
    (( _Dbg_listline > max_line && _Dbg_listline-- ))
    return 0
}

_Dbg_list_columns() {
    typeset colsep='  '
    (($# > 0 )) && { colsep="$1"; shift; }
    (($# != 0)) && return 1
    typeset -a columnized; columnize $_Dbg_linewidth "$colsep"
    typeset -i i
    for ((i=0; i<${#columnized[@]}; i++)) ; do 
	_Dbg_msg "  ${columnized[i]}"
    done

}
