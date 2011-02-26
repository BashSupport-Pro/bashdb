# -*- shell-script -*-
# Enter nested shell
#
#   Copyright (C) 2011 Rocky Bernstein <rocky@gnu.org>
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

_Dbg_shell_temp_profile=$(_Dbg_tempname profile)

_Dbg_help_add shell \
"shell 

Enter a nested shell, not a subshell. Before entering the shell
current variable definitions stored in profile $_Dbg_shell_temp_profile
that profile file is read in via the --init-file option.

The shell that used is taken from the \$SHELL environment variable, 
currently: $SHELL. 

Variables set or changed in the shell do not persist after the shell
is left to to back to the debugger or debugged program
"

# FIXME: add this behavior
# By default variables set or changed in the SHELL are not saved after
# exit of the shell and back to the debugger or debugged program. 
# If you want
# to save the values of individual variables created or changed, use function
# save_var and pass in the name of the variable. For example
# 
# my_var='abc'
# save_var my_var

_Dbg_do_shell() {
    typeset -i _Dbg_rc
    typeset _Dbg_var
    typeset _Dbg_var_exclude=BASHOPTS
    for _Dbg_var in BASH_VERSINFO BASHPID EUID PASPID PPID SHELLOPT UID ; do
	_Dbg_var_exclude+="\\|${_Dbg_var}"
    done
    typeset _Dbg_grep_cmd
    # FIXME: this isn't quite right. We really should filter on 
    # grep -e '^declare -r BASHOPTS\|BSH_VERSINFO ..."
    _Dbg_grep_cmd="grep -v -e $_Dbg_var_exclude"
    typeset -p | $_Dbg_grep_cmd > $_Dbg_shell_temp_profile
    echo 'PS1="bashdb $ "' >>$_Dbg_shell_temp_profile
    ## echo 'save_var() { typeset -p $1 >>${_Dbg_journal} 2>/dev/null; }' >> $_Dbg_shell_temp_profile
    $SHELL --init-file $_Dbg_shell_temp_profile
    rc=$?
    # . $_Dbg_journal
    _Dbg_print_location_and_command
}
