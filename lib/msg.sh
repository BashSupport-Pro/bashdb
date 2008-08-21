# -*- shell-script -*-
# msg.sh - Bourne Again Shell Debugger Input/Output routines
#
#   Copyright (C) 2002, 2003, 2004, 2006, 2008 Rocky Bernstein 
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

# Common funnel for "Undefined command" message
_Dbg_undefined_cmd() {
  _Dbg_msg "Undefined $1 command \"$2\""
}
