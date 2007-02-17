# dbg-hist.inc - Bourne Again Shell Debugger history routines
#
#   Copyright (C) 2002, 2003, 2006, 2007 Rocky Bernstein
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

typeset -i _Dbg_hi_last_stop=0
typeset -i _Dbg_hi=0           # Current next history entry to store into.
typeset -a _Dbg_history=()

# Remove the last command from the history list.
_Dbg_remove_history_item() {
 _Dbg_hi=${#_Dbg_history[@]}-1
  unset _Dbg_history[$_Dbg_hi]
}

# Set to rerun history item, or print history if command is of the form
#  !n:p. If command is "history" then $1 is number of history item. 
# the history command index to run is returned or $_Dbg_hi if 
# there's nothing to run.
# Return value in $history_num
_Dbg_do_history_parse() {

  history_num=$1
  
  _Dbg_hi=${#_Dbg_history[@]}
  [[ -z $history_num ]] && let history_num=$_Dbg_hi-1

  eval "$_seteglob"
  if [[ $_Dbg_cmd == h* ]] ; then
    if [[ $history_num != $int_pat ]] ; then 
      if [[ $history_num == -$int_pat ]] ; then 
	history_num=$_Dbg_hi+$history_num
      else
	_Dbg_msg "Invalid history number skipped: $history_num"
	history_num=-1
      fi
    fi
  else
    # Handle ! form. May need to parse number out number and modifier
    case $_Dbg_cmd in 
      \!\-${int_pat}:p )
	local -a word1
	word1=($(_Dbg_split "!" $_Dbg_cmd))
	local -a word2
	word2=($(_Dbg_split ":" ${word1[0]}))
	local -i num=_Dbg_hi+${word2[0]}
	_Dbg_do_history_list $num $num
	history_num=-1
	;;
      [!]${int_pat}:p )
	local -a word1
	word1=($(_Dbg_split "!" $_Dbg_cmd))
	local -a word2
	word2=($(_Dbg_split ":" ${word1[0]}))
	_Dbg_do_history_list ${word2[0]} ${word2[0]}
	history_num=-1
	;;
      \!\-$int_pat ) 
	local -a word
	word=($(_Dbg_split "!" $_Dbg_cmd))
	history_num=$_Dbg_hi+${word[0]}
	;;
      \!$int_pat ) 
	local -a word
	word=($(_Dbg_split "!" $_Dbg_cmd))
	history_num=${word[0]}
	;;
      '!' ) 
        if [[ $history_num != $int_pat ]] ; then 
	  if [[ $history_num == -$int_pat ]] ; then 
  	    history_num=$_Dbg_hi+$history_num
	  else
	    _Dbg_msg "Invalid history number skipped: $history_num"
	    history_num=-1
	  fi
	fi
        ;;
      * )
      _Dbg_msg "Invalid history number skipped: $_Dbg_cmd"
      history_num=-1
    esac
  fi
  eval "$_resteglob"
}

# Print debugger history $1 is where to start or highest number if not given.
# If $1 is negative, it is how many history items.
# $2 is where to stop or 0 if not given.
_Dbg_do_history_list() {

  eval "$_seteglob"
  if [[ $1 != $int_pat ]] && [[ $1 != -$int_pat ]] && [[ -n $1 ]] ; then 
    _Dbg_msg "Invalid history number: $1"
    eval "$_resteglob"
    return 1
  fi
  eval "$_resteglob"

  _Dbg_hi=${#_Dbg_history[@]}
  local -i n=${1:-$_Dbg_hi-1}
  local -i stop=${2:0}
  local -i i

  # Were we given a count rather than a starting history number? 
  if (( n<0 )) ; then
    ((stop=_Dbg_hi+n))
    ((n=_Dbg_hi-1))
  elif (( n > _Dbg_hi-1 )) ; then
    ((n=_Dbg_hi-1))
  fi

  for (( i=n ; (( i >= stop && i >= 0 )) ; i-- )) ; do
    _Dbg_msg "${i}: ${_Dbg_history[$i]}"
  done
}

# This is put at the so we have something at the end when we debug this.
typeset -r _Dbg_hist_ver=\
'$Id: dbg-hist.inc,v 1.3 2007/02/17 12:07:44 rockyb Exp $'

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: **
