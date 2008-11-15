# -*- shell-script -*-
# Eval and Print commands.
#
#   Copyright (C) 2002, 2003, 2004, 2006, 2008 Rocky Bernstein 
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

# temp file for internal eval'd commands
typeset _Dbg_evalfile=$(_Dbg_tempname eval)

_Dbg_help_add eval \
'eval CMD -- Run eval on CMD.

CMD is a string sent to special shell builtin eval. See also print.'

_Dbg_do_eval() {

  echo ". ${_Dbg_libdir}/dbg-set-d-vars.inc" > $_Dbg_evalfile
  echo "$@" >> $_Dbg_evalfile
  if [[ -n $_Dbg_tty  ]] ; then
    . $_Dbg_evalfile >>$_Dbg_tty
  else
    . $_Dbg_evalfile
  fi
  # We've reset some variables like IFS and PS4 to make eval look
  # like they were before debugger entry - so reset them now.
  _Dbg_set_debugger_internal
}

_Dbg_alias_add 'e' 'eval'

# The arguments in the last "print" command.
typeset _Dbg_last_print_args=''

_Dbg_help_add print \
'print EXPRESSION -- Print EXPRESSION.

EXPRESSION is a string like you would put in a print statement.
See also eval.'

_Dbg_do_print() {
  typeset _Dbg_expr=${@:-"$_Dbg_last_print_args"}
  typeset dq_expr=$(_Dbg_esc_dq "$_Dbg_expr")
  . ${_Dbg_libdir}/dbg-set-d-vars.inc
  eval "_Dbg_msg $_Dbg_expr"
  _Dbg_last_print_args="$dq_expr"
}

_Dbg_alias_add 'p' 'print'
