# Command completion for a condition command
_Dbg_complete_subcmd() {
    eval "list=\${!_Dbg_debugger_$1_commands[@]}"
    COMPREPLY=( $list )
}
