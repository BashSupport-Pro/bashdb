# -*- shell-script -*-
# msg.sh - Bourne Again Shell Debugger Input/Output routines
#
#   Copyright (C) 2002, 2003, 2004, 2006, 2008, 2009 Rocky Bernstein 
#   rocky@gnu.org
#
#   bashdb is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   Bashdb is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with Bashdb; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

# Print an error message
function _Dbg_errmsg {
    typeset -r prefix='**'
    _Dbg_msg "$prefix $@"
}

# Print an error message without the ending carriage return
function _Dbg_errmsg_no_cr {
    typeset -r prefix='**'
    _Dbg_msg_no_cr "$prefix $@"
}

# print message to output device
function _Dbg_msg {
  if (( _Dbg_logging )) ; then
    builtin echo -e "$@" >>$_Dbg_logfid
  fi
  if (( ! _Dbg_logging_redirect )) ; then
    if [[ -n $_Dbg_tty  ]] ; then
      builtin echo -e "$@" >>$_Dbg_tty
    else
      builtin echo -e "$@"
    fi
  fi
}

# print message to output device without a carriage return at the end
function _Dbg_msg_nocr {
  if (( _Dbg_logging )) ; then
    builtin echo -n -e "$@" >>$_Dbg_logfid
  fi
  if (( ! _Dbg_logging_redirect )) ; then
    if [[ -n $_Dbg_tty  ]] ; then
      builtin echo -n -e "$@" >>$_Dbg_tty
    else
      builtin echo -n -e "$@"
    fi
  fi
}

# print message to output device
function _Dbg_printf {
  typeset format=$1
  shift
  if (( _Dbg_logging )) ; then
    builtin printf "$format" "$@" >>$_Dbg_logfid
  fi
  if (( ! _Dbg_logging_redirect )) ; then
    if [[ -n $_Dbg_tty ]] ; then
      builtin printf "$format" "$@" >>$_Dbg_tty
    else
      builtin printf "$format" "$@"
    fi
  fi
  _Dbg_msg ''
}

# print message to output device without a carriage return at the end
function _Dbg_printf_nocr {
  typeset format=$1
  shift 
  if (( _Dbg_logging )) ; then
    builtin printf "$format" "$@" >>$_Dbg_logfid
  fi
  if (( ! _Dbg_logging_redirect )) ; then
    if [[ -n $_Dbg_tty ]] ; then 
      builtin printf "$format" "$@" >>$_Dbg_tty
    else
      builtin printf "$format" "$@"
    fi
  fi
}

_Dbg_confirm() {
    if (( $# < 1 || $# > 2 )) ; then
	_Dbg_response='error'
	return 0
    fi
    _Dbg_confirm_prompt=$1
    typeset _Dbg_confirm_default=${2:-'no'}
    while : ; do 
	if ! read $_Dbg_edit -p "$_Dbg_confirm_prompt" _Dbg_response args \
	    <&$_Dbg_input_desc 2>>$_Dbg_prompt_output ; then
	    break
	fi

	case "$_Dbg_response" in
	    'y' | 'yes' | 'yeah' | 'ya' | 'ja' | 'si' | 'oui' | 'ok' | 'okay' )
		_Dbg_response='y'
		return 0
		;;
	    'n' | 'no' | 'nope' | 'nyet' | 'nein' | 'non' )
		_Dbg_response='n'
		return 0
		;;
	    *)
		if [[ $_Dbg_response =~ '^[ \t]*$' ]] ; then
		    set +x
		    return 0
		else
		    _Dbg_msg "I don't understand \"$_Dbg_response\"."
		    _Dbg_msg "Please try again entering 'yes' or 'no'."
		    _Dbg_response=''
		fi
		;;
	esac

    done
}

# Common funnel for "Undefined command" message
_Dbg_undefined_cmd() {
    if (( $# == 2 )) ; then
	_Dbg_msg "Undefined $1 subcommand \"$2\". Try \"help $1\"."
    else
	_Dbg_msg "Undefined command \"$1\". Try \"help\"."
    fi
}
