# Command completion for a condition command
_Dbg_complete_subcmd() {
    # echo "level 0 called with comp_line: $COMP_LINE , comp_point: $COMP_POINT"
    typeset -a words; 
    typeset subcmds
    IFS=' ' words=( $COMP_LINE )
    if (( ${#words[@]} == 1 )); then 
	eval "subcmds=\${!_Dbg_debugger_$1_commands[@]}"
	COMPREPLY=( $subcmds )
    elif (( ${#words[@]} == 2 )) ; then 
	eval "subcmds=\${!_Dbg_debugger_$1_commands[@]}"
	typeset commands="${!_Dbg_command_help[@]}"
	COMPREPLY=( $(compgen -W  "$subcmds" "${words[1]}" ) )
    else
	COMPREPLY=()
    fi
}
