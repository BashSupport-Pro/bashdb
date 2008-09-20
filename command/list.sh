# -*- shell-script -*-
# list.sh - Some listing commands
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008 Rocky Bernstein
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

_Dbg_help_add list \
'list [START|.|FN] [COUNT] -- List lines of a script.

START is the starting line or dot (.) for current line. Subsequent
list commands continue from the last line listed. If a function name
is given list the text of the function.

If COUNT is omitted, use the setting LISTSIZE. Use "set listsize" to 
change this setting.'

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

  typeset filename
  typeset -i line_number
  typeset full_filename

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
  typeset delim_search_pat=$1
  if [[ -z "$1" ]] ; then
    _Dbg_msg "Need a search pattern"
    return 1
  fi
  shift

  case "$delim_search_pat" in
    [?] )
      ;;
    [?]* )
      typeset -a word
      word=($(_Dbg_split '?' $delim_search_pat))
      _Dbg_last_search_pat=${word[0]}
      ;;
    # Error
    * )
      _Dbg_last_search_pat=$delim_search_pat
  esac
  typeset -i i
  typeset -i max_line=$(_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $_cur_filevar)
  for (( i=_Dbg_listline-1; i > 0 ; i-- )) ; do
    typeset source_line
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

_Dbg_help_add '/' \
'/search/ -- Search forward and list line of a script.'

# /search/
_Dbg_do_search() {
  typeset delim_search_pat=${1}
  if [[ -z "$1" ]] ; then
    _Dbg_msg "Need a search pattern"
    return 1
  fi
  shift
  typeset search_pat
  case "$delim_search_pat" in
    / )
      ;;
    /* )
      typeset -a word
      word=($(_Dbg_split '/' $delim_search_pat))
      _Dbg_last_search_pat=${word[0]}
      ;;
    * )
      _Dbg_last_search_pat=$delim_search_pat
  esac
  typeset -i i
  typeset -i max_line=`_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $_cur_filevar`
  for (( i=_Dbg_listline+1; i < max_line ; i++ )) ; do
    typeset source_line
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
_Dbg_do_list_functions() {

  typeset pat=$1

  typeset -a fns_a
  fns_a=(`_Dbg_get_functions 0 "$pat"`)
  typeset -i i
  for (( i=0; (( i < ${#fns_a[@]} )) ; i++ )) ; do
    _Dbg_msg ${fns_a[$i]}
  done
}

