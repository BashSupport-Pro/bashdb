# -*- shell-script -*-
# show.sh - Show debugger settings
#
#   Copyright (C) 2002, 2003, 2006, 2007, 2008, 2010
#   Rocky Bernstein rocky@gnu.org
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

_Dbg_help_add show ''  # Help routine is elsewhere

# Load in "show" subcommands
for _Dbg_file in ${_Dbg_libdir}/command/show_sub/*.sh ; do 
    source $_Dbg_file
done

_Dbg_do_show() {
    typeset show_cmd=$1
    typeset label=$2

    # Warranty, copying, directories, aliases, and warranty are omitted below.
    typeset -r subcmds="annotate args autoeval autolist basename debugger different editing history linetrace listsize prompt trace-commands width"

    if [[ -z $show_cmd ]] ; then 
	typeset thing
	for thing in $subcmds ; do 
	    _Dbg_do_show $thing 1
	done
	return 0
    fi

    case $show_cmd in 
	al | ali | alia | alias | aliase | aliases )
	    _Dbg_do_show_alias
	    return $?
	    ;;
	ar | arg | args )
	    [[ -n $label ]] && label='args:     '
	    _Dbg_msg \
		"${label}Argument list to give script when debugged program starts is:\n" \
		"      \"${_Dbg_orig_script_args[@]}\"."
	    return 0
	    ;;
	an | ann | anno | annot | annota | annotat | annotate )
	    [[ -n $label ]] && label='annotate: '
	    _Dbg_msg \
		"${label}Annotation_level is $_Dbg_set_annotate."
            return 0
	    ;;
	autoe | autoev | autoeva | autoeval )
	    [[ -n $label ]] && label='autoeval: '
	    _Dbg_msg \
		"${label}Evaluate unrecognized commands is" $(_Dbg_onoff $_Dbg_set_autoeval)
	    return 0
	    ;;
	autol | autoli | autolis | autolist )
	    [[ -n $label ]] && label='autolist: '
	    typeset onoff="on."
	    [[ -z ${_Dbg_cmdloop_hooks["list"]} ]] && onoff='off.'
	    _Dbg_msg \
		"${label}Auto run of 'list' command is ${onoff}"
	    return 0
	    ;;
	b | ba | bas | base | basen | basena | basenam | basename )
	    [[ -n $label ]] && label='basename: '
	    _Dbg_msg \
		"${label}Show short filenames (the basename) in debug output is" $(_Dbg_onoff $_Dbg_set_basename)
	    return 0
	    ;;
	com | comm | comma | comman | command | commands )
	    typeset -i default_hi_start=_Dbg_hi-1
	    if ((default_hi_start < 0)) ; then default_hi_start=0 ; fi
	    typeset hi_start=${2:-$default_hi_start}
	    
	    eval "$_seteglob"
	     case $hi_start in
	    	"+" )
	    	    ((hi_start=_Dbg_hi_last_stop-1))
	    	    ;;
	    	$int_pat | -$int_pat)
                     ;;
	    	* )
	    	    _Dbg_msg "Invalid parameter $hi_start. Need an integer or '+'"
	    esac
	    eval "$_resteglob"
	    
	    typeset -i hi_stop=hi_start-10
	    _Dbg_do_history_list $hi_start $hi_stop
	    _Dbg_hi_last_stop=$hi_stop
	    return 0
	    ;;
	cop | copy| copyi | copyin | copying )
	    _Dbg_do_show_copying
	    return $?
	    ;;
	de|deb|debu|debug|debugg|debugger|debuggi|debuggin|debugging )
	    [[ -n $label ]] && label='debugging: '
	    _Dbg_do_show_debugging $label
	    return $?
	    ;;
	dir|dire|direc|direct|directo|director|directori|directorie|directories)
	    typeset list=${_Dbg_dir[0]}
	    typeset -i n=${#_Dbg_dir[@]}
	    typeset -i i
	    for (( i=1 ; i < n; i++ )) ; do
		list="${list}:${_Dbg_dir[i]}"
	    done

	    _Dbg_msg "Source directories searched: $list"
	    return 0
	    ;;
	e | ed | edi | edit | editi | editin | editing )
	    _Dbg_do_show_editing "$label"
	    return 0
	    ;;
	force | diff | differ | different )
	    [[ -n $label ]] && label='different: '
	    _Dbg_msg \
		"${label}Show stepping forces a new line is" $(_Dbg_onoff $_Dbg_set_different)
	    return 0
	    ;;
	hi|his|hist|histo|histor|history)
	    _Dbg_msg \
		"filename: The filename in which to record the command history is $_Dbg_histfile"
	    _Dbg_msg \
		"save: Saving of history save is" $(_Dbg_onoff $_Dbg_set_history)
	    _Dbg_msg \
		"size: Debugger history size is $_Dbg_history_length"
	    ;;

	lin | line | linet | linetr | linetra | linetrac | linetrace )
	    [[ -n $label ]] && label='line tracing: '
	    typeset onoff="off."
	    (( $_Dbg_linetrace != 0 )) && onoff='on.'
	    _Dbg_msg \
		"${label}Show line tracing is" $onoff
	    _Dbg_msg \
		"${label}Show line trace delay is ${_Dbg_linetrace_delay}."
	    return 0
	    ;;

	lis | list | lists | listsi | listsiz | listsize )
	    [[ -n $label ]] && label='listsize: '
	    _Dbg_msg \
		"${label}Number of source lines ${_Dbg_debugger_name} will list by default is" \
		"$_Dbg_set_listsize."
	    return 0
	    ;;

	lo | log | logg | loggi | loggin | logging )
	    shift
	    _Dbg_do_show_logging $*
	    ;;
	p | pr | pro | prom | promp | prompt )
	    [[ -n $label ]] && label='prompt:   '
	    _Dbg_msg \
		"${label}${_Dbg_debugger_name}'s prompt is:\n" \
		"      \"$_Dbg_prompt_str\"."
	    return 0
	    ;;
	sho|show|showc|showco|showcom|showcomm|showcomma|showcomman|showcommand )
	    [[ -n $label ]] && label='showcommand: '
	    _Dbg_msg \
		"${label}Show commands in debugger prompt is" \
		"$_Dbg_set_show_command."
	    return 0
	    ;;
	t|tr|tra|trac|trace|trace-|tracec|trace-co|trace-com|trace-comm|trace-comma|trace-comman|trace-command|trace-commands )
	    [[ -n $label ]] && label='trace-commands: '
	    _Dbg_msg \
		"${label}State of command tracing is" \
		"$_Dbg_set_trace_commands."
	    return 0
	    ;;
	v | ve | ver | vers | versi | versio | version )
	    _Dbg_do_show_version
	    return 0
	    ;;
	w | wa | war | warr | warra | warran | warrant | warranty )
	    _Dbg_do_info warranty
	    return 0
	    ;;
	wi | wid | width )
	    [[ -n $label ]] && label='width: '
	    _Dbg_msg \
		"${label}Line width is $_Dbg_set_linewidth."
	    return 0
	    ;;
	*)
	    _Dbg_errmsg "Unknown show subcommand: $show_cmd"
	    typeset -a list; list=(${subcmds[@]})
	    typeset columnized=''
	    typeset -i width; ((width=_Dbg_set_linewidth-5))
	    typeset -a columnized; columnize $width
	    typeset -i i
	    _Dbg_errmsg "Show subcommands are:"
	    for ((i=0; i<${#columnized[@]}; i++)) ; do 
		_Dbg_errmsg "  ${columnized[i]}"
	    done
	    return 1
    esac
}
