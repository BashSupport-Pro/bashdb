# -*- shell-script -*-
# "info variables" debugger command
#
#   Copyright (C) 2010, 2014, 2016, 2019 Rocky Bernstein rocky@gnu.org
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


# V [![pat]] List variables and values for whose variables names which
# match pat $1. If ! is used, list variables that *don't* match.
# If pat ($1) is omitted, use * (everything) for the pattern.

_Dbg_help_add_sub info variables '
**info variables**

*info* *variables* [*-i*|*--integer*][*-r*|*--readonly*]*[-x*|*--exports*]

Show global and static variable names.

Options:

    -i | --exports restricted to integer variables
    -r | --readonly restricted to read-only variables
    -x | --exports restricted to exported variables

If multiple flags are given, variables matching *any* of the flags are included.
Note. Bashdb debugger variables, those that start with `_Dbg_` are excluded.

Examples:
---------

    info variables   # show all variabls
    alias s   step   # "s" is now an alias for "step".
                     # The above example is done by default.

' 1

if ! typeset -F getopts_long >/dev/null 2>&1 ; then
    . "${_Dbg_libdir}/getopts_long.sh"
fi

# Should declare typset_flags before calling.
# That it the implit returned value
function _Dbg_info_variables_parse_options {

    typeset -i _Dbg_rc=0

    _Dbg_typeset_flags=""

    OPTLIND=''
    while getopts_long irx opt  \
	integer no_argument     \
        readonly no_argument    \
        exports no_argument     \
	'' $@
    do
	case "$opt" in
	    i | integer )
		_Dbg_typeset_flags="-i $_Dbg_typeset_flags";;
	    r | readonly )
		_Dbg_typeset_flags="-r _$Dbg_typeset_flags";;
	    x | integer )
		_Dbg_typeset_flags="-x $_Dbg_typeset_flags";;
	    * )
		_Dbg_errmsg "Invalid argument in $@; use only -x, -i, or -r"
		_Dbg_rc=1
		;;
	esac
    done
    return $_Dbg_rc
}

function _Dbg_do_info_variables {
    _Dbg_typeset_flags=""
    _Dbg_info_variables_parse_options "$@"
    (( $? != 0 )) && return

    local _Dbg_old_glob="$GLOBIGNORE"
    GLOBIGNORE="*"

    _Dbg_match='*'
    local _Dbg_list=$(declare -p $_Dbg_typeset_flags)
    local _Dbg_old_ifs=${IFS}
    IFS="
"
    local _Dbg_temp=${_Dbg_list}
    _Dbg_list=""
    local -i i=0
    local -a _Dbg_list

    # GLOBIGNORE protects us against using the result of
    # a glob expansion, but it doesn't protect us from
    # actually performing it, and this can bring bash down
    # with a huge _Dbg_source_ variable being globbed.
    # So here we disable globbing momentarily
    set -o noglob
    for _Dbg_item in ${_Dbg_temp}; do
	_Dbg_list[${i}]="${_Dbg_item}"
	i=${i}+1
    done
    set +o noglob
    IFS=${_Dbg_old_ifs}
    local _Dbg_item=""
    local _Dbg_skip=0
    local _Dbg_show_cmd=""
    _Dbg_show_cmd=`echo -e "case \\${_Dbg_item} in \n${_Dbg_match})\n echo yes;;\n*)\necho no;; esac"`

    for (( i=0; (( i < ${#_Dbg_list[@]} )) ; i++ )) ; do
	_Dbg_item=${_Dbg_list[$i]}


	# Ignore all _Dbg_ variables here because the following
	# substitutions takes a long while when it encounters
	# a big _Dbg_source_
	if [[ ${_Dbg_item} =~ "_Dbg_" ]] ; then
	    continue;
	fi


	case ${_Dbg_item} in
	    *\ \(\)\ )
		_Dbg_skip=1
		;;
	    \})
		_Dbg_skip=0
		continue
	esac
	if [[ _Dbg_skip -eq 1 ]]; then
	    continue
	fi
	_Dbg_item=${_Dbg_item/=/==/}
	_Dbg_item=${_Dbg_item%%=[^=]*}
	case ${_Dbg_item} in
	    _=);;
	    *=)
		_Dbg_item=${_Dbg_item%=}
		local _Dbg_show=`eval $_Dbg_show_cmd`
		if [[ "$_Dbg_show" != "$_Dbg_match_inverted" ]]; then
		    if [[ -n ${_Dbg_item} ]]; then
			local _Dbg_var=`declare -p ${_Dbg_typeset_flags} ${_Dbg_item} 2>/dev/null`
			if [[ -n "$_Dbg_var" ]]; then
			    # Uncomment the following 3 lines to use literal
			    # linefeeds
			    #		_Dbg_var=${_Dbg_var//\\\\n/\\n}
			    #                _Dbg_var=${_Dbg_var//
			    #/\n}
			    # Comment the following 3 lines to use literal linefeeds
			    _Dbg_var=${_Dbg_var//\\\\n/\\\\\\n}
			    _Dbg_var=${_Dbg_var//
				/\\n}
			    _Dbg_var=${_Dbg_var#* * }
			    _Dbg_msg ${_Dbg_var}
			fi
		    fi
		fi
		;;
	    *)
		;;
	esac

    done
    GLOBIGNORE=$_Dbg_old_glob
}
