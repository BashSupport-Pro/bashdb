# bashdb-list.inc - Bourne Again Shell Debugger list/search commands
#   Copyright (C) 2002, 2003, 2004, 2006 Rocky Bernstein
#   rockyb@users.sourceforge.net
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

# List search commands/routines

# Last search pattern used.
typeset _Dbg_last_search_pat

# current line to be listed
typeset -i _Dbg_listline

# Print source line in standard format for line $1 of filename $2.  If
# $2 is omitted, use _cur_source_file, if $1 is omitted use _curline.

_Dbg_print_source_line() {
  local line_number=${1:-$_curline}
  local filename=${2:-$_cur_source_file}
  local source_line
  _Dbg_get_source_line $line_number $filename
  filename=$(_Dbg_adjust_filename "$filename")
  _Dbg_msg "(${filename}:${line_number}):
${line_number}:\t${source_line}"

  # If we are at the same place in the file but the command has changed,
  # then we have multiple commands on the line. So print which one we are
  # currently at.
  if [[ $_Dbg_show_command == "on" ]] ; then
      _Dbg_msg "$_Dbg_bash_command"
  elif [[ $_Dbg_last_curline == $_curline ]] \
    && [[ $_Dbg_last_source_file == $_cur_source_file ]] \
    && [[ $_Dbg_last_bash_command != $_Dbg_bash_command \
    && $_Dbg_show_command == "auto" ]] ; then
      _Dbg_msg "$_Dbg_bash_command"
  fi
}

# Print Linetrace output. We also handle output if linetrace expand
# is in effect.
_Dbg_print_linetrace() {
  local line_number=${1:-$_curline}
  local filename=${2:-$_cur_source_file}

  # Remove main + sig-handler  + print_lintrace FUNCNAMES.
  local -i depth=${#FUNCNAME[@]}-3  

  # If called from bashdb script rather than via "bash --debugger", 
  # we are artificially nested one deeper because of the bashdb call.
  if [[ -n $_Dbg_script ]] ; then 
    ((depth--))
  fi

  (( depth < 0 )) && return

  local source_line
  _Dbg_get_source_line $line_number $filename
  filename=$(_Dbg_adjust_filename "$filename")
  _Dbg_msg "(${filename}:${line_number}):
level $BASHDB_LEVEL, subshell $BASH_SUBSHELL, depth $depth:\t${source_line}"
  if (( _Dbg_linetrace_expand )) ; then
#    local expanded_source_line
#    # Replace all double quotes (") with and an escape (\")
#    local esc_source_line="${source_line//\"/\\\"}" 
#    _Dbg_do_eval "expanded_source_line=\"$esc_source_line\"" 2>/dev/null
     _Dbg_do_eval "expanded_source_line=\"$_Dbg_bash_command\"" 2>/dev/null
     _Dbg_msg "+ ${expanded_source_line}"
  fi

  # If we are at the same place in the file but the command has changed,
  # then we have multiple commands on the line. So print which one we are
  # currently at.
  if [[ $_Dbg_show_command == "on" ]] ; then
      _Dbg_msg "$_Dbg_bash_command"
  elif [[ $_Dbg_last_curline == $_curline ]] \
    && [[ $_Dbg_last_source_file == $_cur_source_file ]] \
    && [[ $_Dbg_last_bash_command != $_Dbg_bash_command \
    && $_Dbg_show_command == "auto" ]] ; then
      _Dbg_msg "$_Dbg_bash_command"
  fi
}


# l [start|.] [cnt] List cnt lines from line start.
# l sub       List source code fn
_Dbg_do_list() {
  if [[ -n $1 ]] ; then
    first_arg=$1
    shift
  else
    first_arg=.
  fi

  if [ $first_arg == '.' ] ; then
    _Dbg_list $_cur_source_file $*
    return
  fi

  local filename
  local -i line_number
  local full_filename

  _Dbg_linespec_setup $first_arg

  if [[ -n $full_filename ]] ; then 
    (( $line_number ==  0 )) && line_number=1
    _Dbg_check_line $line_number "$full_filename"
    (( $? == 0 )) && \
      _Dbg_list "$full_filename" "$line_number" $*
  else
    _Dbg_file_not_read_in $filename
  fi
}

# /search/
_Dbg_do_search_back() {
  local delim_search_pat=$1
  if [[ -z "$1" ]] ; then
    _Dbg_msg "Need a search pattern"
    return 1
  fi
  shift

  case "$delim_search_pat" in
    [?] )
      ;;
    [?]* )
      local -a word
      word=($(_Dbg_split '?' $delim_search_pat))
      _Dbg_last_search_pat=${word[0]}
      ;;
    # Error
    * )
      _Dbg_last_search_pat=$delim_search_pat
  esac
  local -i i
  local -i max_line=`_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $_cur_filevar`
  for (( i=_Dbg_listline-1; i > 0 ; i-- )) ; do
    local source_line
    _Dbg_get_source_line $i
    eval "$_seteglob"
    if [[ $source_line == *$_Dbg_last_search_pat* ]] ; then
      eval "$_resteglob"
      _Dbg_do_list $i 1
      _Dbg_listline=$i
      return 0
    fi
    eval "$_resteglob"
  done
  _Dbg_msg "search pattern: $_Dbg_last_search_pat not found."
  return 1

}

# /search/
_Dbg_do_search() {
  local delim_search_pat=${1}
  if [[ -z "$1" ]] ; then
    _Dbg_msg "Need a search pattern"
    return 1
  fi
  shift
  local search_pat
  case "$delim_search_pat" in
    / )
      ;;
    /* )
      local -a word
      word=($(_Dbg_split "/" $delim_search_pat))
      _Dbg_last_search_pat=${word[0]}
      ;;
    * )
      _Dbg_last_search_pat=$delim_search_pat
  esac
  local -i i
  local -i max_line=`_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $_cur_filevar`
  for (( i=_Dbg_listline+1; i < max_line ; i++ )) ; do
    local source_line
    _Dbg_get_source_line $i
    eval "$_seteglob"
    if [[ $source_line == *$_Dbg_last_search_pat* ]] ; then
      eval "$_resteglob"
      _Dbg_do_list $i 1
      _Dbg_listline=$i
      return 0
    fi
    eval "$_resteglob"
  done
  _Dbg_msg "search pattern: $_Dbg_last_search_pat not found."
  return 1

}

# S [[!]pat] List Subroutine names [not] matching a pattern
# Pass along whether or not to print "system" functions?
_Dbg_do_list_subroutines() {

  local pat=$1

  local -a fns_a
  fns_a=(`_Dbg_get_functions 0 "$pat"`)
  local -i i
  for (( i=0; (( i < ${#fns_a[@]} )) ; i++ )) ; do
    _Dbg_msg ${fns_a[$i]}
  done
}

# list $3 lines starting at line $2 of file $1. If $1 is '', use
# $_cur_source_file value.  If $3 is ommited, print $_Dbg_listsize
# lines. if $2 is omitted, use global variable $_curline.

_Dbg_list() {
    local filename=${1:-$_cur_source_file}

    if [[ $2 = . ]]; then
      _Dbg_listline=$_curline
    elif [[ -n $2 ]] ; then
      _Dbg_listline=$2
    fi
    (( _Dbg_listline==0 && _Dbg_listline++))

    local -ir cnt=${3:-$_Dbg_listsize}
    local -ir n=$((_Dbg_listline+cnt-1))

    local source_line

    local filevar=`_Dbg_file2var $filename`
    local is_read
    is_read=`_Dbg_get_assoc_scalar_entry "_Dbg_read_" $filevar`
    [ $is_read ] || _Dbg_readin $filename
    local -i max_line=`_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $filevar`
    #   echo "debug: -- max_line: $max_line --"

    if (( _Dbg_listline > max_line )) ; then
      _Dbg_msg \
	"Line number $_Dbg_listline out of range;" \
      "$filename has $max_line lines."
      return 1
    fi

    for ((  ; (( _Dbg_listline <= n && _Dbg_listline <= max_line )) \
            ; _Dbg_listline++ )) ; do
     local prefix="   "
     local source_line
     _Dbg_get_source_line $_Dbg_listline $filename

     (( _Dbg_listline == _curline )) \
       && [[ $filename == $_cur_source_file ]] &&  prefix="==>"
     _Dbg_printf "%3d:%s%s" $_Dbg_listline "$prefix" "$source_line"
    done
    (( _Dbg_listline > max_line && _Dbg_listline-- ))
    return 0
}

# This is put at the so we have something at the end when we debug this.
_Dbg_list_ver='$Id: dbg-list.inc,v 1.10 2006/12/26 21:19:08 rockyb Exp $'

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
